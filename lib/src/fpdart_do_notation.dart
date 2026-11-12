import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'fpdart_type_checkers.dart';

class DoInvocation {
  final InstanceCreationExpression node;

  final FunctionExpression callback;

  final String? extractorName;

  const DoInvocation({
    required this.node,
    required this.callback,
    required this.extractorName,
  });

  FunctionBody get body => callback.body;

  bool get isAsync => body.isAsynchronous;

  bool isExtractorCall(Expression expression) {
    final name = extractorName;
    if (name == null) return false;

    // Edge case: `$(step)` parses as a FunctionExpressionInvocation or, if unresolved, a call
    final invocation = expression.unParenthesized;

    if (invocation is FunctionExpressionInvocation) {
      final function = invocation.function;
      return function is SimpleIdentifier && function.name == name;
    }

    return invocation is MethodInvocation &&
        invocation.realTarget == null &&
        invocation.methodName.name == name;
  }

  static DoInvocation? tryRead(InstanceCreationExpression node) {
    final constructorName = node.constructorName;
    if (constructorName.name?.name != 'Do') return null;

    final element = constructorName.element;
    if (element == null) return null;
    if (!anyFpdartChecker.isExactly(element.enclosingElement)) return null;

    final arguments = node.argumentList.arguments;
    if (arguments.length != 1) return null;

    final callback = arguments.first.argumentExpression;
    if (callback is! FunctionExpression) return null;

    final parameters = callback.parameters?.parameters;
    final extractorName = parameters == null || parameters.isEmpty
        ? null
        : parameters.first.name?.lexeme;

    return DoInvocation(
      node: node,
      callback: callback,
      extractorName: extractorName,
    );
  }
}

abstract class DoBodyVisitor extends RecursiveAstVisitor<void> {
  final DoInvocation invocation;

  DoBodyVisitor(this.invocation);

  void run() => invocation.body.accept(this);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (DoInvocation.tryRead(node) != null) return;
    super.visitInstanceCreationExpression(node);
  }
}
