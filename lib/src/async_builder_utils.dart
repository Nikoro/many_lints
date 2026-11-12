import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';

import 'type_checker.dart';

bool createsNewAsyncSource(Expression expression, TypeChecker typeChecker) {
  final unwrapped = _unwrap(expression);

  return switch (unwrapped) {
    InstanceCreationExpression() => _isMatchingType(unwrapped, typeChecker),

    // Edge case: a constructor without type arguments also parses as a MethodInvocation
    MethodInvocation() => _isMatchingType(unwrapped, typeChecker),

    FunctionExpressionInvocation() => _isMatchingType(unwrapped, typeChecker),

    _ => false,
  };
}

Expression _unwrap(Expression expression) => switch (expression) {
  ParenthesizedExpression(:final expression) => _unwrap(expression),
  PostfixExpression(operator: Token(lexeme: '!'), :final operand) => _unwrap(
    operand,
  ),
  _ => expression,
};

bool _isMatchingType(Expression expression, TypeChecker typeChecker) {
  final type = expression.staticType;
  if (type == null) return false;
  return typeChecker.isAssignableFromType(type);
}
