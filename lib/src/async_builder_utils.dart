/// Shared detection for `FutureBuilder`/`StreamBuilder` rules.
///
/// Both rules flag the same mistake: passing a *freshly created* async
/// source to the builder. Because `build()` can run arbitrarily often, a
/// new Future/Stream is created on every rebuild, the builder resets to its
/// waiting state, and the work is redone — often triggering a network call
/// per frame.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';

import 'type_checker.dart';

/// Returns the argument expression for [name] in [arguments], or `null`.
Expression? namedArgument(NodeList<Argument> arguments, String name) {
  for (final argument in arguments) {
    if (argument is NamedArgument && argument.name.lexeme == name) {
      return argument.argumentExpression;
    }
  }
  return null;
}

/// Whether [expression] *creates* a new async source rather than referring to
/// an existing one.
///
/// This is deliberately conservative: it reports only shapes that are certain
/// to allocate. Anything it cannot prove — a bare identifier, a property
/// access, a conditional, an unresolved expression — is treated as safe, so
/// the rule stays silent instead of guessing.
bool createsNewAsyncSource(Expression expression, TypeChecker typeChecker) {
  final unwrapped = _unwrap(expression);

  return switch (unwrapped) {
    // Future(...), Future.delayed(...), Stream.fromIterable(...)
    InstanceCreationExpression() => _isMatchingType(unwrapped, typeChecker),

    // fetchData(), repository.load(), someStream()
    //
    // A constructor without type arguments also parses as a MethodInvocation,
    // which this covers as well.
    MethodInvocation() => _isMatchingType(unwrapped, typeChecker),

    // (() async => ...)() — an immediately invoked async closure
    FunctionExpressionInvocation() => _isMatchingType(unwrapped, typeChecker),

    // Anything else (identifiers, field access, ternaries, `await` results,
    // unresolved code) is assumed to be an existing instance.
    _ => false,
  };
}

/// Strips parentheses and `!` so `(fetch())!` is still seen as a call.
Expression _unwrap(Expression expression) => switch (expression) {
  ParenthesizedExpression(:final expression) => _unwrap(expression),
  PostfixExpression(operator: Token(lexeme: '!'), :final operand) => _unwrap(
    operand,
  ),
  _ => expression,
};

bool _isMatchingType(Expression expression, TypeChecker typeChecker) {
  final type = expression.staticType;
  // Unresolved type — stay silent rather than guess.
  if (type == null) return false;
  return typeChecker.isAssignableFromType(type);
}
