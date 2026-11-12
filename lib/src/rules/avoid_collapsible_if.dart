import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class AvoidCollapsibleIf extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_collapsible_if',
    'This if statement can be merged with the nested one.',
    correctionMessage: "Combine both conditions with '&&'.",
  );

  AvoidCollapsibleIf()
    : super(
        name: 'avoid_collapsible_if',
        description:
            'Warns when an if statement contains only another if statement '
            'and both can be merged with &&.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addIfStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidCollapsibleIf rule;

  _Visitor(this.rule);

  @override
  void visitIfStatement(IfStatement node) {
    if (node.elseStatement != null) return;

    // Edge case: an if-case clause cannot be merged with &&
    if (node.caseClause != null) return;

    final inner = _soleNestedIf(node.thenStatement);
    if (inner == null) return;

    if (inner.elseStatement != null) return;
    if (inner.caseClause != null) return;

    rule.reportAtToken(node.ifKeyword);
  }

  IfStatement? _soleNestedIf(Statement statement) => switch (statement) {
    IfStatement() => statement,
    Block(:final statements) when statements.length == 1 =>
      statements.first is IfStatement ? statements.first as IfStatement : null,
    _ => null,
  };
}
