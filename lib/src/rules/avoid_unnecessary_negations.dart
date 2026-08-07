import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a negation cancels another negation.
///
/// `!!flag` and `!(a != b)` say the same thing as `flag` and `a == b`, but
/// force the reader to unwind the negations first. They usually appear
/// after a condition is inverted and the inner expression is left as it
/// was.
class AvoidUnnecessaryNegations extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_negations',
    'This negation cancels another negation.',
    correctionMessage:
        'Remove both negations and state the condition '
        'directly.',
  );

  AvoidUnnecessaryNegations()
    : super(
        name: 'avoid_unnecessary_negations',
        description:
            'Warns when a negation is applied to an already-negated '
            'expression, such as !!flag or !(a != b).',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addPrefixExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnnecessaryNegations rule;

  _Visitor(this.rule);

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (node.operator.lexeme != '!') return;

    final operand = _unwrapParentheses(node.operand);

    final isDoubleNegation =
        (operand is PrefixExpression && operand.operator.lexeme == '!') ||
        (operand is BinaryExpression && operand.operator.lexeme == '!=');

    if (isDoubleNegation) {
      rule.reportAtNode(node);
    }
  }

  Expression _unwrapParentheses(Expression expression) => switch (expression) {
    ParenthesizedExpression(:final expression) => _unwrapParentheses(
      expression,
    ),
    _ => expression,
  };
}
