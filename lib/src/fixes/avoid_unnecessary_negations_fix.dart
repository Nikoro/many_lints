import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that collapses a double negation.
class AvoidUnnecessaryNegationsFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidUnnecessaryNegations',
    DartFixKindPriority.standard,
    'Remove double negation',
  );

  AvoidUnnecessaryNegationsFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
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
    } else {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(outer), replacement);
    });
  }

  Expression _unwrapParentheses(Expression expression) => switch (expression) {
    ParenthesizedExpression(:final expression) => _unwrapParentheses(
      expression,
    ),
    _ => expression,
  };
}
