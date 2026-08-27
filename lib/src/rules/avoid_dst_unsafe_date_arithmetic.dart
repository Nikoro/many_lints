import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../date_time_arithmetic.dart';
import '../many_lints_rule.dart';

/// Warns when whole days are added to or subtracted from a local [DateTime]
/// with a [Duration].
///
/// `Duration` measures *absolute elapsed time*, but a calendar day is not
/// always 24 hours long. In a zone that observes daylight saving time, adding
/// `Duration(days: 1)` to a local `DateTime` lands on the wrong wall-clock
/// time whenever the span crosses a transition:
///
/// ```dart
/// // Europe/Warsaw, DST starts 2025-03-30 02:00.
/// DateTime(2025, 3, 29, 12).add(const Duration(days: 1));
/// // 2025-03-30 13:00 — an hour later than intended.
///
/// DateTime(2025, 3, 30).add(const Duration(days: 1));
/// // 2025-03-31 01:00 — midnight is no longer midnight.
/// ```
///
/// The `DateTime` constructor normalises out-of-range components against the
/// calendar instead, so it preserves the wall-clock time across a transition.
///
/// Sub-day units are not reported: `Duration(hours: 2)` genuinely means two
/// elapsed hours, and absolute arithmetic is the correct semantics for it.
/// UTC receivers are not reported either, since UTC has no transitions.
class AvoidDstUnsafeDateArithmetic extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_dst_unsafe_date_arithmetic',
    "Adding whole days with a 'Duration' shifts the wall-clock time across a "
        'daylight saving transition.',
    correctionMessage:
        "Use the 'DateTime' constructor to do calendar arithmetic, or operate "
        'on a UTC value.',
  );

  AvoidDstUnsafeDateArithmetic()
    : super(
        name: 'avoid_dst_unsafe_date_arithmetic',
        description:
            'Warns when whole days are added to or subtracted from a local '
            'DateTime with a Duration.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, context);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidDstUnsafeDateArithmetic rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final shift = DateTimeShift.tryRead(node, context: context);
    if (shift == null) return;
    if (shift.isUtcReceiver) return;

    rule.reportAtNode(node);
  }
}
