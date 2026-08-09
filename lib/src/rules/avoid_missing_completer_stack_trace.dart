import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../type_checker.dart';

/// Warns when `Completer.completeError` is called without a stack trace.
///
/// `completeError` takes an optional second argument, and when it is omitted
/// the error arrives at the `await` with a stack trace that starts where the
/// future was *completed*, not where the failure happened. Inside a catch
/// block the original trace is right there in `st` — passing it keeps the
/// error traceable to its real origin.
///
/// **Bad:**
/// ```dart
/// try {
///   doWork();
/// } catch (e, st) {
///   completer.completeError(e); // `st` discarded
/// }
/// ```
///
/// **Good:**
/// ```dart
/// try {
///   doWork();
/// } catch (e, st) {
///   completer.completeError(e, st);
/// }
/// ```
class AvoidMissingCompleterStackTrace extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_missing_completer_stack_trace',
    "'completeError' is called without a stack trace.",
    correctionMessage:
        'Pass the stack trace as the second argument so the error stays '
        'traceable to where it was thrown.',
  );

  AvoidMissingCompleterStackTrace()
    : super(
        name: 'avoid_missing_completer_stack_trace',
        description:
            'Warns when Completer.completeError is called without passing a '
            'stack trace.',
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
  final AvoidMissingCompleterStackTrace rule;

  _Visitor(this.rule);

  static const _completerChecker = TypeChecker.fromUrl('dart:async#Completer');

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'completeError') return;

    // Already passing a stack trace.
    if (node.argumentList.arguments.length >= 2) return;

    final targetType = node.realTarget?.staticType;
    if (targetType == null) return;
    if (!_completerChecker.isAssignableFromType(targetType)) return;

    // `require_inside_catch: false` widens the rule to every call site. The
    // default keeps it to catch blocks, where a stack trace is provably in
    // scope and omitting it is unambiguously a loss — elsewhere the caller
    // may genuinely have none to pass.
    final requireInsideCatch = rule.config.boolOption(
      'require_inside_catch',
      defaultValue: true,
    );

    if (requireInsideCatch) {
      // Require a catch that actually *binds* a stack trace. Bare `catch (e)`
      // has none in scope, so there is nothing the author could pass and the
      // report would be unactionable.
      final catchClause = _enclosingCatchClause(node);
      if (catchClause?.stackTraceParameter == null) return;
    }

    rule.reportAtNode(node);
  }

  /// The nearest enclosing `catch` clause, stopping at a function boundary so
  /// a closure defined inside a catch block is not credited with its trace.
  CatchClause? _enclosingCatchClause(AstNode node) {
    for (AstNode? current = node; current != null; current = current.parent) {
      if (current is CatchClause) return current;
      if (current is FunctionExpression || current is MethodDeclaration) {
        return null;
      }
    }

    return null;
  }
}
