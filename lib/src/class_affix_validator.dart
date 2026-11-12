import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import 'many_lints_rule.dart';
import 'rule_config.dart';
import 'type_checker.dart';

enum AffixKind {
  prefix('prefix'),
  suffix('suffix');

  const AffixKind(this.optionKey);

  final String optionKey;

  bool matches(String name, String affix) => switch (this) {
    AffixKind.prefix => name.startsWith(affix),
    AffixKind.suffix => name.endsWith(affix),
  };
}

class AffixEntry {
  final String type;

  final String? package;

  final String affix;

  final bool ignorePrivate;

  const AffixEntry({
    required this.type,
    required this.package,
    required this.affix,
    required this.ignorePrivate,
  });

  TypeChecker get typeChecker =>
      TypeChecker.fromName(type, packageName: package);
}

List<AffixEntry> readAffixEntries(RuleConfig config, AffixKind kind) {
  final ruleWideIgnorePrivate = config.boolOption(
    'ignore_private',
    defaultValue: false,
  );

  final entries = <AffixEntry>[];
  for (final raw in config.entriesOption('entries')) {
    final type = raw['type'];
    final affix = raw[kind.optionKey];
    if (type is! String || type.isEmpty) continue;
    if (affix is! String || affix.isEmpty) continue;

    final package = raw['package'];
    final ignorePrivate = raw['ignore_private'];

    entries.add(
      AffixEntry(
        type: type,
        package: package is String && package.isNotEmpty ? package : null,
        affix: affix,
        ignorePrivate: ignorePrivate is bool
            ? ignorePrivate
            : ruleWideIgnorePrivate,
      ),
    );
  }

  return entries;
}

AffixEntry? findViolatedEntry({
  required List<AffixEntry> entries,
  required InterfaceElement element,
  required String className,
  required AffixKind kind,
}) {
  for (final entry in entries) {
    if (entry.ignorePrivate && className.startsWith('_')) continue;

    final checker = entry.typeChecker;
    // Edge case: isSuperOf is reflexive, and the configured base type needs no affix
    if (checker.isExactly(element)) continue;
    if (!checker.isSuperOf(element)) continue;
    if (kind.matches(className, entry.affix)) continue;

    return entry;
  }

  return null;
}

abstract class ClassAffixValidator extends ManyLintsRule {
  final AffixKind kind;

  ClassAffixValidator({
    required super.name,
    required super.description,
    required this.kind,
  });

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _ClassAffixVisitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class _ClassAffixVisitor extends SimpleAstVisitor<void> {
  final ClassAffixValidator rule;

  _ClassAffixVisitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) return;

    // Edge case: rule instances are singletons reused across package roots, so no caching
    final entries = readAffixEntries(rule.config, rule.kind);
    if (entries.isEmpty) return;

    final name = node.namePart.typeName;
    final className = name.lexeme;

    final violated = findViolatedEntry(
      entries: entries,
      element: element,
      className: className,
      kind: rule.kind,
    );
    if (violated == null) return;

    // Edge case: the LintCode must stay one stable instance for registerFixForRule
    rule.reportAtToken(name, arguments: [violated.affix, className]);
  }
}
