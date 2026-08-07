import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that removes negations which do not change the result.
///
/// Covers all four shapes the rule reports: `!!x`, `!(a != b)`, `!true`, and
/// a comparison with a negation on both sides (`!a == !b`).
class AvoidUnnecessaryNegationsFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidUnnecessaryNegations',
    DartFixKindPriority.standard,
    'Remove unnecessary negation',
  );

  AvoidUnnecessaryNegationsFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // `!a == !b` is reported at the comparison, not at either negation.
    final comparison = node.thisOrAncestorOfType<BinaryExpression>();
    if (comparison != null && _isNegatedComparison(comparison)) {
      final left = _negatedOperand(comparison.leftOperand)!;
      final right = _negatedOperand(comparison.rightOperand)!;

      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(
          range.node(comparison),
          '${left.toSource()} ${comparison.operator.lexeme} '
          '${right.toSource()}',
        );
      });
      return;
    }

    final outer = node.thisOrAncestorOfType<PrefixExpression>();
    if (outer == null || outer.operator.lexeme != '!') return;

    final operand = _unwrapParentheses(outer.operand);

    final String replacement;
    if (operand is PrefixExpression && operand.operator.lexeme == '!') {
      // `!!x` -> `x`
      replacement = _unwrapParentheses(operand.operand).toSource();
    } else if (operand is BinaryExpression && operand.operator.lexeme == '!=') {
      // `!(a != b)` -> `a == b`
      replacement =
          '${operand.leftOperand.toSource()} == '
          '${operand.rightOperand.toSource()}';
    } else if (operand is BooleanLiteral) {
      // `!true` -> `false`
      replacement = '${!operand.value}';
    } else {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(outer), replacement);
    });
  }

  /// Whether both operands of an `==`/`!=` comparison are negated.
  bool _isNegatedComparison(BinaryExpression node) {
    final operator = node.operator.lexeme;
    if (operator != '==' && operator != '!=') return false;

    return _negatedOperand(node.leftOperand) != null &&
        _negatedOperand(node.rightOperand) != null;
  }

  /// Returns the expression under a `!`, or `null` when there is no `!`.
  Expression? _negatedOperand(Expression expression) {
    final unwrapped = _unwrapParentheses(expression);
    if (unwrapped is PrefixExpression && unwrapped.operator.lexeme == '!') {
      return _unwrapParentheses(unwrapped.operand);
    }
    return null;
  }

  Expression _unwrapParentheses(Expression expression) => switch (expression) {
    ParenthesizedExpression(:final expression) => _unwrapParentheses(
      expression,
    ),
    _ => expression,
  };
}
