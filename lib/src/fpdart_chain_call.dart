import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import 'fpdart_type_checkers.dart';

/// A resolved `flatMap` call on an fpdart type, with its callback unpacked.
///
/// The five `flatMap`-narrowing assists all start from the same three
/// questions — is the cursor on a `flatMap`, is the receiver really an fpdart
/// type, and what does the callback look like — so they ask them once here
/// rather than each growing its own copy that can drift.
typedef FpdartChainCall = ({
  /// The whole `receiver.flatMap(...)` invocation.
  MethodInvocation invocation,

  /// The callback passed to it.
  FunctionExpression callback,

  /// The callback's single parameter, or `null` when it declares none.
  FormalParameter? parameter,

  /// The callback's body expression, or `null` for a block body.
  ///
  /// Every one of these assists rewrites a one-expression callback; a block
  /// body is a real function and stays a `flatMap`.
  Expression? body,
});

/// The `flatMap` call at or above [node], or `null` when there is none.
///
/// Walks the parent chain because an assist fires wherever the cursor happens
/// to sit — on the method name, inside the callback, on the receiver.
///
/// Matching is by resolved type, not by the name `flatMap` alone: an unrelated
/// class with a method of that name must never be offered an fpdart
/// combinator.
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

/// Whether [invocation]'s receiver is an fpdart wrapper.
bool _isFpdartReceiver(MethodInvocation invocation) {
  final target = invocation.realTarget;
  if (target == null) return false;

  final type = target.staticType;
  return type != null && anyFpdartChecker.isAssignableFromType(type);
}

/// Whether [parameter] is never read inside [body].
///
/// `_` is the conventional spelling, but a named-yet-unused parameter is the
/// same situation, so this asks the question by element rather than by name.
/// A callback declaring no parameter at all counts as not using it.
bool parameterIsUnused(FormalParameter? parameter, AstNode body) {
  if (parameter == null) return true;

  final element = parameter.declaredFragment?.element;
  if (element == null) return false;

  final finder = _ElementReferenceFinder(element);
  body.accept(finder);

  return !finder.found;
}

/// Detects any reference to one element.
class _ElementReferenceFinder extends RecursiveAstVisitor<void> {
  _ElementReferenceFinder(this.target);

  final Element target;
  bool found = false;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.element == target) found = true;
  }
}

/// The argument `andThen` should receive for a callback returning [body].
///
/// A no-argument invocation is emitted as a tear-off, which is what makes the
/// result read as a name rather than as another closure. Anything else — an
/// invocation with arguments, a constructor call, a property read — keeps a
/// thunk, because tearing those off is either impossible or changes when they
/// are evaluated.
///
/// Shared by the `andThen` assist and `prefer_and_then`'s fix so the two
/// cannot disagree about which shape they emit.
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
