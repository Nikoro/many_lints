import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/dart/ast/token.dart';

import '../many_lints_rule.dart';

/// Warns when an `if`/`else` or a conditional expression tests a negated
/// condition, so the reader meets the branches in the harder order.
///
/// ```dart
/// if (!user.isActive) {
///   showInactive();
/// } else {
///   showActive();
/// }
/// ```
///
/// The `else` here is the positive case, which means the reader has to hold a
/// negation to know what the second branch is *for*. Swapping the branches
/// states each one directly.
///
/// Only reported when there is an `else` to swap with. A bare `if (!x)` is a
/// guard, which is the clearest form there is — and [PreferEarlyReturn]
/// actively asks for it, so reporting it here would set the two rules
/// fighting.
///
/// `!=` counts as a negation by default, since `if (a != b) ... else ...` has
/// the same inverted shape — but never against `null` or `0`. `x != null` is
/// the null check the language is built around, and `byPoints != 0 ? ... : ...`
/// is the comparator tie-break idiom; both state a positive fact, and both
/// turned up as false positives on a production codebase.
///
/// Set `report_not_equal: false` to skip `!=` entirely and report only `!`.
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
    // No `else` means this is a guard, which is the shape to prefer.
    if (elseStatement == null) return;

    // `else if` chains encode an ordered sequence of tests; swapping the first
    // pair would reorder the whole chain rather than flip one branch.
    if (elseStatement is IfStatement) return;

    // A pattern `if` binds variables the swapped branch could not see.
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
      // `x != null` and `x != 0` are how Dart states a positive fact — the
      // first is the null check the language is built around, the second the
      // comparator tie-break idiom (`byPoints != 0 ? byPoints : ...`). Both
      // came out of a production run as false positives, and inverting either
      // reads worse. Only a comparison against some other value has the
      // inverted shape this rule is about.
      if (_isNullOrZero(expression.rightOperand) ||
          _isNullOrZero(expression.leftOperand)) {
        return false;
      }

      return rule.config.boolOption('report_not_equal', defaultValue: true);
    }

    return false;
  }

  /// Whether [expression] is `null` or the integer `0`, the two right-hand
  /// sides that make `!=` read as a positive assertion rather than a negation.
  bool _isNullOrZero(Expression expression) => switch (expression) {
    NullLiteral() => true,
    IntegerLiteral(:final value) => value == 0,
    _ => false,
  };
}
