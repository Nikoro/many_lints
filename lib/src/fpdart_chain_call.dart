import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import 'fpdart_type_checkers.dart';

typedef FpdartChainCall = ({
  MethodInvocation invocation,

  FunctionExpression callback,

  FormalParameter? parameter,

  Expression? body,
});

FpdartChainCall? readFpdartFlatMap(AstNode? node) {
  for (var current = node; current != null; current = current.parent) {
    if (current is! MethodInvocation) continue;
    if (current.methodName.name != 'flatMap') continue;
    if (!_isFpdartReceiver(current)) continue;

    final arguments = current.argumentList.arguments;
    if (arguments.length != 1) continue;

    final callback = arguments.single;
    if (callback is! FunctionExpression) continue;

    final parameters = callback.parameters?.parameters;
    if (parameters != null && parameters.length > 1) continue;

    final body = callback.body;

    return (
      invocation: current,
      callback: callback,
      parameter: parameters == null || parameters.isEmpty
          ? null
          : parameters.single,
      body: body is ExpressionFunctionBody ? body.expression : null,
    );
  }

  return null;
}

bool _isFpdartReceiver(MethodInvocation invocation) {
  final target = invocation.realTarget;
  if (target == null) return false;

  final type = target.staticType;
  return type != null && anyFpdartChecker.isAssignableFromType(type);
}

bool parameterIsUnused(FormalParameter? parameter, AstNode body) {
  if (parameter == null) return true;

  final element = parameter.declaredFragment?.element;
  if (element == null) return false;

  final finder = _ElementReferenceFinder(element);
  body.accept(finder);

  return !finder.found;
}

class _ElementReferenceFinder extends RecursiveAstVisitor<void> {
  _ElementReferenceFinder(this.target);

  final Element target;
  bool found = false;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.element == target) found = true;
  }
}

String andThenArgumentFor(Expression body) {
  if (body is MethodInvocation &&
      body.argumentList.arguments.isEmpty &&
      body.typeArguments == null) {
    final target = body.realTarget;
    final receiver = target == null ? '' : '${target.toSource()}.';

    return '$receiver${body.methodName.name}';
  }

  return '() => ${body.toSource()}';
}
