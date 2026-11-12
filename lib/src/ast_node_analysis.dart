import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';

import './type_checker.dart';

ClassDeclaration? enclosingClassDeclaration(AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is ClassDeclaration) return current;
    current = current.parent;
  }
  return null;
}

T? enclosingOfType<T extends AstNode>(AstNode node) {
  AstNode? current = node;
  while (current != null) {
    if (current is T) return current;
    current = current.parent;
  }
  return null;
}

NamedArgument? namedArgumentNode(NodeList<Argument> arguments, String name) {
  for (final argument in arguments) {
    if (argument is NamedArgument && argument.name.lexeme == name) {
      return argument;
    }
  }
  return null;
}

Expression? namedArgumentValue(NodeList<Argument> arguments, String name) =>
    namedArgumentNode(arguments, name)?.argumentExpression;

String indentOf(String content, int offset) {
  // Edge case: lastIndexOf rejects a negative start, and offset 0 has nothing before it
  if (offset <= 0) return '';

  final lineStart = content.lastIndexOf('\n', offset - 1) + 1;
  return content.substring(lineStart, offset);
}

({Expression node, ArgumentList argumentList})? resolveWidgetCall(
  AstNode node,
) {
  // Edge case: an unnamed ConstructorName shares its range with the deeper NamedType
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

bool hasOverrideAnnotation(MethodDeclaration method) =>
    method.metadata.any((a) => a.name.name == 'override');

bool isExpressionExactlyType(Expression expression, TypeChecker checker) {
  if (expression.staticType case final type?) {
    return checker.isExactlyType(type);
  }
  return false;
}

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
        return false;
      }
    } else {
      return false;
    }
  }
  return hasParameter;
}

Expression? maybeGetSingleReturnExpression(FunctionBody body) {
  return switch (body) {
    ExpressionFunctionBody(:final expression) ||
    BlockFunctionBody(
      block: Block(statements: [ReturnStatement(:final expression?)]),
    ) => expression,
    _ => null,
  };
}

const _invertedComparisons = <String, String>{
  '==': '!=',
  '!=': '==',
  '<': '>=',
  '>=': '<',
  '>': '<=',
  '<=': '>',
};

String negateExpression(Expression expr) {
  if (expr is PrefixExpression && expr.operator.type == TokenType.BANG) {
    return expr.operand.toSource();
  }
  if (expr is BinaryExpression) {
    final inverted = _invertedComparisons[expr.operator.lexeme];
    if (inverted != null) {
      return '${expr.leftOperand.toSource()} $inverted '
          '${expr.rightOperand.toSource()}';
    }
  }
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
  return '!(${expr.toSource()})';
}

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

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
