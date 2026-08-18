import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:many_lints/src/date_time_arithmetic.dart';

/// Fix that rewrites day arithmetic onto the `DateTime` constructor, which
/// normalises against the calendar and so preserves the wall-clock time.
///
/// Deliberately narrow: it only fires when the receiver is a simple identifier
/// and the shift is a plain integer literal number of days. Evaluating the
/// receiver twice would be wrong for anything with a side effect, and a
/// non-literal amount cannot be folded into the `day` argument as text.
class AvoidDstUnsafeDateArithmeticFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidDstUnsafeDateArithmetic',
    DartFixKindPriority.standard,
    'Use the DateTime constructor for calendar arithmetic',
  );

  AvoidDstUnsafeDateArithmeticFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final invocation = node.thisOrAncestorOfType<MethodInvocation>();
    if (invocation == null) return;

    final shift = DateTimeShift.tryRead(invocation);
    if (shift == null) return;

    final days = shift.literalDays;
    if (days == null) return;

    // Re-reading the receiver is only safe when it is a plain variable.
    final receiver = shift.receiver.unParenthesized;
    if (receiver is! SimpleIdentifier) return;
    final target = receiver.name;

    final signedDays = shift.isSubtraction ? -days : days;
    final dayOperator = signedDays.isNegative ? '-' : '+';
    final dayOffset = '$target.day $dayOperator ${signedDays.abs()}';

    final replacement =
        'DateTime($target.year, $target.month, $dayOffset, '
        '$target.hour, $target.minute, $target.second, '
        '$target.millisecond, $target.microsecond)';

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(invocation), replacement);
    });
  }
}
