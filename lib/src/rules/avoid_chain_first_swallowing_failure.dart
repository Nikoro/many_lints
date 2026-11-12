import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';

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
