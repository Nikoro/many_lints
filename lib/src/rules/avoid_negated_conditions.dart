import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/dart/ast/token.dart';

import '../many_lints_rule.dart';

class AvoidNegatedConditions extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_negated_conditions',
    'This condition is negated, so the `else` branch is the positive case.',
    correctionMessage:
        'Invert the condition and swap the branches, so each reads directly.',
  );

  AvoidNegatedConditions()
    : super(
        name: 'avoid_negated_conditions',
        description:
            'Warns when an if/else or conditional expression tests a negated '
            'condition.',
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
    registry.addConditionalExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidNegatedConditions rule;

  _Visitor(this.rule);

  @override
  void visitIfStatement(IfStatement node) {
    final elseStatement = node.elseStatement;
    if (elseStatement == null) return;

    if (elseStatement is IfStatement) return;

    // Edge case: pattern variables are scoped to the then-branch, so swapping would unbind them
    if (node.caseClause != null) return;

    if (!_isNegated(node.expression)) return;

    rule.reportAtNode(node.expression);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    if (!_isNegated(node.condition)) return;

    rule.reportAtNode(node.condition);
  }

  bool _isNegated(Expression condition) {
    final expression = condition.unParenthesized;

    if (expression is PrefixExpression) {
      return expression.operator.type == TokenType.BANG;
    }

    if (expression is BinaryExpression &&
        expression.operator.type == TokenType.BANG_EQ) {
      if (_isNullOrZero(expression.rightOperand) ||
          _isNullOrZero(expression.leftOperand)) {
        return false;
      }

      return rule.config.boolOption('report_not_equal', defaultValue: true);
    }

    return false;
  }

  bool _isNullOrZero(Expression expression) => switch (expression) {
    NullLiteral() => true,
    IntegerLiteral(:final value) => value == 0,
    _ => false,
  };
}
