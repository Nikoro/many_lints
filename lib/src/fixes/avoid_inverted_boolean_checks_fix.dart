import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that replaces a negated comparison with the opposite operator.
class AvoidInvertedBooleanChecksFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidInvertedBooleanChecks',
    DartFixKindPriority.standard,
    'Use the opposite operator',
  );

  AvoidInvertedBooleanChecksFix({required super.context});

  static const _opposites = {'<': '>=', '<=': '>', '>': '<=', '>=': '<'};

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final prefix = node.thisOrAncestorOfType<PrefixExpression>();
    if (prefix == null || prefix.operator.lexeme != '!') return;

    final operand = prefix.operand;
    if (operand is! ParenthesizedExpression) return;

    final inner = operand.expression;
    if (inner is! BinaryExpression) return;

    final opposite = _opposites[inner.operator.lexeme];
    if (opposite == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.node(prefix),
        '${inner.leftOperand.toSource()} $opposite '
        '${inner.rightOperand.toSource()}',
      );
    });
  }
}
