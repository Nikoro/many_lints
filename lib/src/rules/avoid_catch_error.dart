import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../type_checker.dart';

/// Warns when `Future.catchError` is used instead of `try`/`catch`.
///
/// `catchError` takes an untyped `Function`, so the analyzer cannot check its
/// signature. A callback with the wrong number of parameters compiles
/// perfectly and then throws at runtime — and only on the error path, which is
/// exactly the path least likely to be covered by a test.
///
/// The `test` argument has a second trap: when it returns `false` the error is
/// not handled at all but silently flows on to the next handler, which reads
/// like the error was caught.
///
/// **Bad:**
/// ```dart
/// repository.load().catchError((err, st) => fallback);
/// ```
///
/// **Good:**
/// ```dart
/// try {
///   await repository.load();
/// } catch (err, st) {
///   // handle
/// }
/// ```
class AvoidCatchError extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_catch_error',
    "Avoid using 'catchError'.",
    correctionMessage:
        "Use 'await' with a 'try'/'catch' block instead, so the handler's "
        'signature is checked at compile time.',
  );

  AvoidCatchError()
    : super(
        name: 'avoid_catch_error',
        description:
            'Warns when Future.catchError is used instead of try/catch, whose '
            'handler signature the analyzer can verify.',
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
  final AvoidCatchError rule;

  _Visitor(this.rule);

  static const _futureChecker = TypeChecker.fromUrl('dart:async#Future');

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'catchError') return;

    // Confirm the receiver really is a Future, so an unrelated user-defined
    // `catchError` is not reported.
    final targetType = node.realTarget?.staticType;
    if (targetType == null) return;
    if (!_futureChecker.isAssignableFromType(targetType)) return;

    rule.reportAtNode(node.methodName);
  }
}
