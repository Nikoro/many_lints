import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../pattern_entry.dart';

class MatchPattern extends ManyLintsRule {
  static const LintCode code = LintCode(
    'match_pattern',
    "'{0}' matches a pattern this project rewrites.{1}",
    correctionMessage: 'Use the form this project prefers.',
  );

  MatchPattern()
    : super(
        name: 'match_pattern',
        description:
            'Reports code matching a project-supplied pattern, with the '
            "project's own replacement offered as a fix.",
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
    registry.addPropertyAccess(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final MatchPattern rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) =>
      _check(node, PatternNode.methodInvocation);

  @override
  void visitPropertyAccess(PropertyAccess node) =>
      _check(node, PatternNode.propertyAccess);

  void _check(AstNode node, PatternNode kind) {
    final entries = readPatternEntries(rule.config);
    if (entries.isEmpty) return;

    final source = node.toSource();
    final entry = findPatternEntry(
      entries: entries,
      node: kind,
      source: source,
      relativePath: rule.relativePath,
    );
    if (entry == null) return;

    rule.reportAtNode(node, arguments: [source, patternMessageSuffix(entry)]);
  }
}
