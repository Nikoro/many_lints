import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that rewrites a hand-written null check into `Option.fromNullable`.
///
/// The rule has already established that the two branches are a `Some` of the
/// tested value and a `None`, so the whole conditional collapses to one call
/// on that value. The tested operand is re-derived here rather than parsed out
/// of the message, so a reworded diagnostic cannot break the fix.
class PreferFromNullableFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferFromNullable',
    DartFixKindPriority.standard,
    "Replace with 'Option.fromNullable'",
  );

  PreferFromNullableFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossSingleFile;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final conditional = node.thisOrAncestorOfType<ConditionalExpression>();
    if (conditional == null) return;

    final condition = conditional.condition.unParenthesized;
    if (condition is! BinaryExpression) return;

    final tested = _nullTestedOperand(condition);
    if (tested == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.node(conditional),
        'Option.fromNullable(${tested.toSource()})',
      );
    });
  }

  /// The operand compared against `null`.
  Expression? _nullTestedOperand(BinaryExpression condition) {
    final left = condition.leftOperand.unParenthesized;
    final right = condition.rightOperand.unParenthesized;

    if (right is NullLiteral) return left;
    if (left is NullLiteral) return right;
    return null;
  }
}
