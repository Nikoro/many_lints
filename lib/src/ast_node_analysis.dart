import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';

import './type_checker.dart';

/// Walks up the AST to find the nearest enclosing [ClassDeclaration].
///
/// Starts at [node]'s *parent*, so a [ClassDeclaration] passed in is not
/// returned as its own ancestor. That differs from [enclosingOfType], which
/// starts at [node] itself.
ClassDeclaration? enclosingClassDeclaration(AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is ClassDeclaration) return current;
    current = current.parent;
  }
  return null;
}

/// Walks up from [node] — including [node] itself — to the nearest ancestor of
/// type [T].
///
/// Mirrors the analyzer's own `thisOrAncestorOfType`, kept here so the several
/// fixes that hand-rolled this loop share one spelling.
T? enclosingOfType<T extends AstNode>(AstNode node) {
  AstNode? current = node;
  while (current != null) {
    if (current is T) return current;
    current = current.parent;
  }
  return null;
}

/// Returns the [NamedArgument] called [name] in [arguments], or `null`.
///
/// Fixes generally want the node itself, because deleting or replacing an
/// argument needs its `name` token; rules more often want only the value, for
/// which [namedArgumentValue] is the shorter spelling.
NamedArgument? namedArgumentNode(NodeList<Argument> arguments, String name) {
  for (final argument in arguments) {
    if (argument is NamedArgument && argument.name.lexeme == name) {
      return argument;
    }
  }
  return null;
}

/// Returns the value passed for the named argument [name], or `null`.
Expression? namedArgumentValue(NodeList<Argument> arguments, String name) =>
    namedArgumentNode(arguments, name)?.argumentExpression;

/// Returns the whitespace that indents the line containing [offset].
///
/// Used by fixes that synthesise a statement and must line it up with the code
/// it is inserted beside.
String indentOf(String content, int offset) {
  // `offset == 0` is the start of the file: there is no preceding character to
  // search, and `lastIndexOf` rejects a negative start index outright.
  if (offset <= 0) return '';

  final lineStart = content.lastIndexOf('\n', offset - 1) + 1;
  return content.substring(lineStart, offset);
}

/// Resolves a widget-call diagnostic's reported node into the whole call
/// expression and its argument list.
///
/// A widget constructor reaches a fix as one of two unrelated AST shapes: with
/// `const`, `new` or explicit type arguments it parses as an
/// [InstanceCreationExpression] reported at its [ConstructorName]; a bare
/// `Foo(...)` parses as a [MethodInvocation] reported at its
/// [SimpleIdentifier]. Fixes that replace the *whole call* treat the two
/// identically, so they share this lookup.
///
/// Returns `null` when [node] is neither shape — the caller should then leave
/// the source untouched.
///
/// Not for fixes that replace only the [ConstructorName] itself: a
/// [MethodInvocation] has no node with that range, so accepting it here would
/// silently widen the replaced range.
({Expression node, ArgumentList argumentList})? resolveWidgetCall(
  AstNode node,
) {
  // For an unnamed constructor, `ConstructorName` and its `NamedType` child
  // share a source range and the covering node resolves to the deeper one, so
  // look up before type-testing.
  final targetNode = node.thisOrAncestorOfType<ConstructorName>() ?? node;

  if (targetNode is ConstructorName) {
    final parent = targetNode.parent;
    if (parent is! InstanceCreationExpression) return null;
    return (node: parent, argumentList: parent.argumentList);
  }
  if (targetNode is SimpleIdentifier) {
    final parent = targetNode.parent;
    if (parent is! MethodInvocation) return null;
    return (node: parent, argumentList: parent.argumentList);
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
    if (argument case NamedArgument(
      name: Token(lexeme: final argumentName),
      :final argumentExpression,
    )) {
      if (ignoredParameters.contains(argumentName)) {
        continue;
      } else if (argumentName == parameter &&
          argumentExpression is! NullLiteral &&
          argumentExpression.staticType?.nullabilitySuffix !=
              NullabilitySuffix.question) {
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
