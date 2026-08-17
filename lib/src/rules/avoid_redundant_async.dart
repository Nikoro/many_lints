import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../type_checker.dart';

/// Warns when a function is marked `async` but never awaits.
///
/// `async` without `await` is not automatically redundant: it can wrap a raw
/// value in a future or turn a synchronous throw into an asynchronous error.
/// Those cases are left alone.
///
/// A function whose every return expression is already a `Future` needs no
/// `async` to be awaited by its callers, so removing the keyword keeps the
/// signature and leaves every return type valid.
class AvoidRedundantAsync extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_redundant_async',
    'This function is `async` but never awaits.',
    correctionMessage:
        'Remove `async` and return the future directly, or await inside it.',
  );

  AvoidRedundantAsync()
    : super(
        name: 'avoid_redundant_async',
        description:
            'Warns when an async function neither awaits nor throws and every '
            'return path already produces a compatible Future.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, context);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidRedundantAsync rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  static const _futureChecker = TypeChecker.fromUrl('dart:async#Future');

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) => _check(
    node.functionExpression.body,
    node.declaredFragment?.element.returnType,
    node.name,
  );

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // An override's `async` may be required to satisfy the supertype's
    // return type, and removing it is not the caller's decision to make.
    if (node.metadata.any((a) => a.name.name == 'override')) return;

    _check(node.body, node.declaredFragment?.element.returnType, node.name);
  }

  void _check(FunctionBody body, DartType? returnType, Token name) {
    if (!body.isAsynchronous) return;

    // `async*` is a stream generator; the keyword is what makes it one.
    if (body.isGenerator) return;

    final collector = _AwaitCollector();
    body.accept(collector);
    if (collector.foundAwait || collector.foundThrow) return;

    if (returnType == null) return;
    final returned = _returnedExpressions(body);
    if (returned == null || returned.isEmpty) return;

    // This is the safety boundary for the diagnostic. `async` is required by
    // `Future<int> f() async => 1`; suggesting its removal there produces
    // `Future<int> f() => 1`, which does not compile. Only report when every
    // path already returns a Future assignable to the declared return type.
    for (final expression in returned) {
      final expressionType = expression.staticType;
      if (expressionType == null ||
          expressionType is DynamicType ||
          expressionType is NeverType ||
          !_futureChecker.isAssignableFromType(expressionType) ||
          !context.typeSystem.isAssignableTo(
            expressionType,
            returnType,
            strictCasts: false,
          )) {
        return;
      }
    }

    rule.reportAtToken(name);
  }

  /// Expressions returned on every explicit path, or `null` when removing
  /// `async` could expose a fall-through path or a bare `return`.
  List<Expression>? _returnedExpressions(FunctionBody body) {
    if (body case ExpressionFunctionBody(:final expression)) {
      return [expression];
    }
    if (body is! BlockFunctionBody) return null;

    final statements = body.block.statements;
    if (statements.isEmpty || statements.last is! ReturnStatement) return null;
    final last = statements.last as ReturnStatement;
    if (last.expression == null) return null;

    final collector = _ReturnCollector();
    body.block.accept(collector);
    if (collector.hasBareReturn) return null;
    return collector.expressions;
  }
}

/// Looks for an `await` belonging to this function body.
class _AwaitCollector extends RecursiveAstVisitor<void> {
  bool foundAwait = false;
  bool foundThrow = false;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    foundAwait = true;
  }

  /// `await for` suspends just as `await` does.
  @override
  void visitForStatement(ForStatement node) {
    if (node.awaitKeyword != null) foundAwait = true;
    super.visitForStatement(node);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    foundThrow = true;
  }

  /// A nested function's `await` belongs to that function, not to this one.
  @override
  void visitFunctionExpression(FunctionExpression node) {}
}

class _ReturnCollector extends RecursiveAstVisitor<void> {
  final expressions = <Expression>[];
  bool hasBareReturn = false;

  @override
  void visitReturnStatement(ReturnStatement node) {
    final expression = node.expression;
    if (expression == null) {
      hasBareReturn = true;
    } else {
      expressions.add(expression);
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}
