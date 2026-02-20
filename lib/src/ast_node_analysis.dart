import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';

import './type_checker.dart';

/// Walks up the AST to find the nearest enclosing [ClassDeclaration].
ClassDeclaration? enclosingClassDeclaration(AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is ClassDeclaration) return current;
    current = current.parent;
  }
  return null;
}

/// Returns whether a [MethodDeclaration] has the `@override` annotation.
bool hasOverrideAnnotation(MethodDeclaration method) =>
    method.metadata.any((a) => a.name.name == 'override');

/// Checks whether an expression's static type exactly matches the given type.
bool isExpressionExactlyType(Expression expression, TypeChecker checker) {
  if (expression.staticType case final type?) {
    return checker.isExactlyType(type);
  }
  return false;
}

/// Checks whether an instance creation uses only the specified named parameter.
///
/// Returns true when the [node] has:
/// - Only one relevant named argument whose name equals [parameter]
/// - The argument value is not a null literal and the argument type is not
///   nullable (i.e. not `T?`)
/// - No other arguments are present, except those explicitly listed in
///   [ignoredParameters]
bool isInstanceCreationExpressionOnlyUsingParameter(
  InstanceCreationExpression node, {
  required String parameter,
  Set<String> ignoredParameters = const {},
}) {
  var hasParameter = false;

  for (final argument in node.argumentList.arguments) {
    if (argument case NamedExpression(
      name: Label(label: SimpleIdentifier(name: final argumentName)),
      :final expression,
      :final staticType,
    )) {
      if (ignoredParameters.contains(argumentName)) {
        continue;
      } else if (argumentName == parameter &&
          expression is! NullLiteral &&
          staticType?.nullabilitySuffix != NullabilitySuffix.question) {
        hasParameter = true;
      } else {
        // Other named arguments are not allowed
        return false;
      }
    } else {
      // Other arguments are not allowed
      return false;
    }
  }
  return hasParameter;
}

/// Given a function body, returns the single return expression if there is one.
Expression? maybeGetSingleReturnExpression(FunctionBody body) {
  return switch (body) {
    ExpressionFunctionBody(:final expression) ||
    BlockFunctionBody(
      block: Block(statements: [ReturnStatement(:final expression?)]),
    ) => expression,
    _ => null,
  };
}

/// Negates an expression, handling double negation and parenthesization.
String negateExpression(Expression expr) {
  // Double negation removal: !x -> x
  if (expr is PrefixExpression && expr.operator.type == TokenType.BANG) {
    return expr.operand.toSource();
  }
  // Simple expressions don't need parentheses
  if (expr is SimpleIdentifier ||
      expr is PrefixedIdentifier ||
      expr is MethodInvocation ||
      expr is PropertyAccess ||
      expr is IndexExpression ||
      expr is ParenthesizedExpression ||
      expr is PrefixExpression ||
      expr is BooleanLiteral) {
    return '!${expr.toSource()}';
  }
  // Binary and other complex expressions need parentheses
  return '!(${expr.toSource()})';
}

/// Builds a replacement expression for .every() with negated predicate.
String? buildEveryReplacement(String collection, Expression predicate) {
  if (predicate is! FunctionExpression) return null;

  final body = predicate.body;
  final innerExpr = maybeGetSingleReturnExpression(body);
  if (innerExpr == null) return null;

  final paramList = predicate.parameters;
  if (paramList == null) return null;
  final params = paramList.toSource();
  final negated = negateExpression(innerExpr);
  return '$collection.every($params => $negated)';
}

/// Extension on `Iterable` providing additional utility methods.
extension IterableExtension<T> on Iterable<T> {
  /// Returns the first element satisfying [test], or `null` if none found.
  ///
  /// Unlike `Iterable.firstWhere`, this does not throw if no element matches.
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
