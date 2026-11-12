import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_do_notation.dart';
import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';

const _chainingMethods = {
  'map',
  'flatMap',
  'chainEither',
  'mapLeft',
  'andThen',
  'alt',
  'orElse',
};

const _programmerErrors = {
  'UnimplementedError',
  'UnsupportedError',
  'StateError',
  'AssertionError',
};

class AvoidThrowInFpCallback extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_throw_in_fp_callback',
    'Avoid throwing inside an fpdart callback.',
    correctionMessage:
        'Return a failure in the error channel instead, so the pipeline '
        'short-circuits and the caller can handle it.',
  );

  AvoidThrowInFpCallback()
    : super(
        name: 'avoid_throw_in_fp_callback',
        description:
            'Warns when a throw inside an fpdart callback or Do block escapes '
            'the error channel the pipeline is built to carry.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidThrowInFpCallback rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final invocation = DoInvocation.tryRead(node);
    if (invocation == null) return;

    _ThrowFinder(rule, invocation).run();
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    final methods = rule.config.nameSetOption(
      'methods',
      defaultValue: _chainingMethods,
    );
    if (!methods.contains(methodName)) return;

    final targetType = node.realTarget?.staticType;
    if (targetType == null) return;
    if (!anyFpdartChecker.isAssignableFromType(targetType)) return;

    for (final argument in node.argumentList.arguments) {
      final callback = argument.argumentExpression;
      if (callback is! FunctionExpression) continue;
      callback.body.accept(_CallbackThrowFinder(rule));
    }
  }
}

class _ThrowFinder extends DoBodyVisitor {
  final AvoidThrowInFpCallback rule;

  _ThrowFinder(this.rule, super.invocation);

  @override
  void visitThrowExpression(ThrowExpression node) {
    if (_isAllowedProgrammerError(rule, node)) return;
    rule.reportAtNode(node);
  }
}

class _CallbackThrowFinder extends RecursiveAstVisitor<void> {
  final AvoidThrowInFpCallback rule;

  _CallbackThrowFinder(this.rule);

  @override
  void visitThrowExpression(ThrowExpression node) {
    if (_isAllowedProgrammerError(rule, node)) return;
    rule.reportAtNode(node);
  }
}

bool _isAllowedProgrammerError(
  AvoidThrowInFpCallback rule,
  ThrowExpression node,
) {
  if (!rule.config.boolOption('ignore_unimplemented', defaultValue: true)) {
    return false;
  }

  final thrown = node.expression;
  final typeName = switch (thrown) {
    InstanceCreationExpression() => thrown.constructorName.type.name.lexeme,
    MethodInvocation(target: null) => thrown.methodName.name,
    _ => null,
  };

  return typeName != null && _programmerErrors.contains(typeName);
}
