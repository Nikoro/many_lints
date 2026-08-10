import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_do_notation.dart';
import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';

/// The chaining methods whose callbacks must route failures through the error
/// channel rather than throwing.
const _chainingMethods = {
  'map',
  'flatMap',
  'chainEither',
  'mapLeft',
  'andThen',
  'alt',
  'orElse',
};

/// Errors that signal a programmer mistake rather than a domain outcome.
///
/// These are exempt by default: they mark a branch that should never run, so
/// routing them through the error channel would give a caller a `Left` it can
/// neither handle nor meaningfully report.
const _programmerErrors = {
  'UnimplementedError',
  'UnsupportedError',
  'StateError',
  'AssertionError',
};

/// Warns when a `throw` appears inside an fpdart callback or `Do` block.
///
/// fpdart's whole premise is that failure travels in the value — the `Left` of
/// an `Either`, the `None` of an `Option`. A `throw` inside `map`, `flatMap`
/// or a `Do` body leaves that channel entirely: it escapes the pipeline as an
/// ordinary exception, so a caller that carefully folds every failure still
/// crashes. This is the first of the four pitfalls fpdart documents in its own
/// `do_constructor_pitfalls` example.
///
/// **Bad:**
/// ```dart
/// Option.Do(($) {
///   if ($(testOption) == 'test') {
///     throw Exception('Error');
///   }
///   return 'success';
/// });
/// ```
///
/// **Good:**
/// ```dart
/// Option.Do(($) {
///   final value = $(testOption);
///   return $(value == 'test' ? Option<String>.none() : Option.of('success'));
/// });
/// ```
///
/// ## Options
///
/// - `ignore_unimplemented`: when `true` (the default), a thrown
///   `UnimplementedError`, `UnsupportedError`, `StateError` or `AssertionError`
///   is allowed — those mark unreachable branches, not domain failures.
/// - `additional_methods`: extra callback-taking method names to check, for
///   projects that wrap fpdart's combinators in their own.
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

    // Only fpdart's own combinators: a `map` on an Iterable is unrelated, and
    // throwing there is ordinary Dart.
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

/// Reports `throw`s directly inside a `Do` body.
class _ThrowFinder extends DoBodyVisitor {
  final AvoidThrowInFpCallback rule;

  _ThrowFinder(this.rule, super.invocation);

  @override
  void visitThrowExpression(ThrowExpression node) {
    if (_isExempt(rule, node)) return;
    rule.reportAtNode(node);
  }
}

/// Reports `throw`s inside a combinator callback.
class _CallbackThrowFinder extends RecursiveAstVisitor<void> {
  final AvoidThrowInFpCallback rule;

  _CallbackThrowFinder(this.rule);

  @override
  void visitThrowExpression(ThrowExpression node) {
    if (_isExempt(rule, node)) return;
    rule.reportAtNode(node);
  }
}

/// Whether [node] throws an error that marks a programmer mistake.
bool _isExempt(AvoidThrowInFpCallback rule, ThrowExpression node) {
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
