import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';

/// Warns when `chainFirst` on a failable type discards the failure of its
/// effect.
///
/// fpdart declares:
///
/// ```dart
/// TaskEither<L, R> chainFirst<C>(TaskEither<L, C> Function(R b) chain) =>
///     flatMap((b) => chain(b).map((c) => b).orElse((l) => TaskEither.right(b)));
/// ```
///
/// The trailing `orElse` turns a failing effect back into success, so the
/// pipeline carries on with the original value. The name reads like "run this
/// step too", which is why it gets used for checks and writes, where a
/// swallowed failure is a bug: an authorization check that cannot reject, a
/// save that fails silently.
///
/// This is the counterpart of the `ConvertFlatMapToChainFirst` assist, which
/// offers `chainFirst` knowing it drops the failure.
///
/// **Bad:**
/// ```dart
/// final saved = parse(input).chainFirst(save);
/// ```
///
/// **Good:**
/// ```dart
/// final saved = parse(input).flatMap((user) => save(user).map((_) => user));
/// ```
///
/// ## Options
///
/// - `ignore_tests`: when `true` (the default), files under `test/` are not
///   reported.
class AvoidChainFirstSwallowingFailure extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_chain_first_swallowing_failure',
    "'chainFirst' discards the failure of its effect.",
    correctionMessage:
        'Use flatMap((value) => effect(value).map((_) => value)) so a failing '
        'effect fails the pipeline; keep chainFirst only when ignoring that '
        'failure is the decision.',
  );

  AvoidChainFirstSwallowingFailure()
    : super(
        name: 'avoid_chain_first_swallowing_failure',
        description:
            'Warns when chainFirst on Either or TaskEither silently turns a '
            'failing effect into success.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidChainFirstSwallowingFailure rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'chainFirst') return;

    if (rule.config.boolOption('ignore_tests', defaultValue: true) &&
        (rule.relativePath?.startsWith('test/') ?? false)) {
      return;
    }

    final targetType = node.realTarget?.staticType;
    if (targetType == null) return;
    if (!failableFpdartChecker.isAssignableFromType(targetType)) return;

    rule.reportAtNode(node.methodName);
  }
}
