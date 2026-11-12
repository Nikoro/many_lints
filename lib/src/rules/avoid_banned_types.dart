import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../banned_entry.dart';
import '../many_lints_rule.dart';

class AvoidBannedTypes extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_banned_types',
    "The type '{0}' is banned here.{1}",
    correctionMessage: 'Use a permitted type instead.',
  );

  AvoidBannedTypes()
    : super(
        name: 'avoid_banned_types',
        description: 'Warns when a banned type is named in a file.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addNamedType(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidBannedTypes rule;

  _Visitor(this.rule);

  @override
  void visitNamedType(NamedType node) {
    final entries = readBannedEntries(rule.config);
    if (entries.isEmpty) return;

    final element = node.element;
    if (element == null) return;

    // Edge case: the declared name, so an import prefix cannot hide a banned type
    final typeName = element.name;
    if (typeName == null || typeName.isEmpty) return;

    final banned = _findBanned(entries, element, typeName);
    if (banned == null) return;

    rule.reportAtToken(node.name, arguments: [typeName, messageSuffix(banned)]);
  }

  BannedEntry? _findBanned(
    List<BannedEntry> entries,
    Element element,
    String typeName,
  ) {
    final byName = findBannedEntry(
      entries: entries,
      value: typeName,
      relativePath: rule.relativePath,
    );
    if (byName != null) return byName;

    final uri = element.library?.identifier;
    if (uri == null) return null;

    return findBannedEntry(
      entries: entries,
      value: '$uri#$typeName',
      relativePath: rule.relativePath,
    );
  }
}
