import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import 'many_lints_rule.dart';
import 'rule_config.dart';
import 'type_checker.dart';

/// Which end of a class name an affix applies to.
enum AffixKind {
  prefix('prefix'),
  suffix('suffix');

  const AffixKind(this.optionKey);

  /// The per-entry YAML key carrying the affix for this direction.
  final String optionKey;

  /// Whether [name] already satisfies [affix] in this direction.
  bool matches(String name, String affix) => switch (this) {
    AffixKind.prefix => name.startsWith(affix),
    AffixKind.suffix => name.endsWith(affix),
  };
}

/// One configured `entries:` item: a base type plus the affix its subtypes
/// must carry.
class AffixEntry {
  /// The base type's name, e.g. `Bloc`.
  final String type;

  /// The package declaring [type], or `null` to match any library.
  final String? package;

  /// The prefix or suffix required of subtypes.
  final String affix;

  /// Whether classes named with a leading `_` are skipped.
  final bool ignorePrivate;

  const AffixEntry({
    required this.type,
    required this.package,
    required this.affix,
    required this.ignorePrivate,
  });

  /// Matches a subtype of [type] regardless of how it is derived: `isSuperOf`
  /// walks `allSupertypes`, which covers `extends`, `implements`, `with` and
  /// indirect ancestors alike.
  TypeChecker get typeChecker =>
      TypeChecker.fromName(type, packageName: package);
}

/// Reads the `entries:` list from [config] in the [kind] direction.
///
/// Takes a [RuleConfig] rather than a rule so the quick fix — which has no
/// rule instance — can resolve exactly the same entries the rule matched.
///
/// Entries missing `type` or their affix key are skipped: a plugin cannot
/// report problems against a YAML file, so a malformed entry has to degrade
/// quietly rather than break analysis of the whole package.
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

/// Returns the first entry in [entries] that [element] violates, or `null`
/// when the class is correctly named or matches nothing.
///
/// First match wins, so a class covered by two entries is reported once.
AffixEntry? findViolatedEntry({
  required List<AffixEntry> entries,
  required InterfaceElement element,
  required String className,
  required AffixKind kind,
}) {
  for (final entry in entries) {
    if (entry.ignorePrivate && className.startsWith('_')) continue;

    final checker = entry.typeChecker;
    // `isSuperOf` is reflexive, so the configured base type matches itself.
    // Requiring `Repository` to be named `DbRepository` is nonsense — and for
    // a type owned by a dependency the user could not act on it anyway.
    if (checker.isExactly(element)) continue;
    if (!checker.isSuperOf(element)) continue;
    if (kind.matches(className, entry.affix)) continue;

    return entry;
  }

  return null;
}

/// Base class for the two configurable class-naming rules.
///
/// Both are entirely config-driven: with no `entries:` they report nothing, so
/// installing this package never forces a naming convention on anyone.
abstract class ClassAffixValidator extends ManyLintsRule {
  /// Which end of the name this rule constrains.
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

    // Read config inside the callback: rule instances are long-lived
    // singletons reused across package roots, so this cannot be cached.
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

    // The affix varies per class, so it travels as a message argument rather
    // than being baked into the LintCode — the code must stay a single stable
    // instance for `registerFixForRule` to find the fix.
    rule.reportAtToken(name, arguments: [violated.affix, className]);
  }
}
