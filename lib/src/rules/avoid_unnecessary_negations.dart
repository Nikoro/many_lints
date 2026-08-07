import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a negation can be removed without changing the meaning.
///
/// Four shapes are reported:
///
/// * `!!flag` — a negation cancelling another negation.
/// * `!(a != b)` — a negation cancelling an inequality.
/// * `!true` — negating a boolean literal, which is just the other literal.
/// * `!a == !b` and `!a != !b` — negating both sides of a comparison, which
///   leaves the result unchanged.
///
/// They usually appear after a condition is inverted and the inner
/// expression is left as it was.
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
    registry.addBinaryExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnnecessaryNegations rule;

  _Visitor(this.rule);

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (node.operator.lexeme != '!') return;

    final operand = _unwrapParentheses(node.operand);

    final isRemovable =
        (operand is PrefixExpression && operand.operator.lexeme == '!') ||
        (operand is BinaryExpression && operand.operator.lexeme == '!=') ||
        // `!true` is just `false`; the negation carries no information.
        operand is BooleanLiteral;

    if (isRemovable) {
      rule.reportAtNode(node);
    }
  }

  /// Reports `!a == !b` and `!a != !b`.
  ///
  /// Negating both operands of an equality check cancels out, so both `!`
  /// can go. The comparison itself is left as it is.
  @override
  void visitBinaryExpression(BinaryExpression node) {
    final operator = node.operator.lexeme;
    if (operator != '==' && operator != '!=') return;

    if (!_isNegation(node.leftOperand)) return;
    if (!_isNegation(node.rightOperand)) return;

    rule.reportAtNode(node);
  }

  bool _isNegation(Expression expression) {
    final unwrapped = _unwrapParentheses(expression);
    return unwrapped is PrefixExpression && unwrapped.operator.lexeme == '!';
  }

  Expression _unwrapParentheses(Expression expression) => switch (expression) {
    ParenthesizedExpression(:final expression) => _unwrapParentheses(
      expression,
    ),
    _ => expression,
  };
}
