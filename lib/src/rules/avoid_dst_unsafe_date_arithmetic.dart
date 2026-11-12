import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../date_time_arithmetic.dart';
import '../many_lints_rule.dart';

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
