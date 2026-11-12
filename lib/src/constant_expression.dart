import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';

const comparisonOperators = {
  TokenType.EQ_EQ,
  TokenType.BANG_EQ,
  TokenType.LT,
  TokenType.GT,
  TokenType.LT_EQ,
  TokenType.GT_EQ,
};

bool isConstantExpression(Expression expression) {
  var expr = expression;
  while (expr is ParenthesizedExpression) {
    expr = expr.expression;
  }

  return switch (expr) {
    IntegerLiteral() => true,
    DoubleLiteral() => true,
    SimpleStringLiteral() => true,
    BooleanLiteral() => true,
    NullLiteral() => true,

    TypedLiteral(constKeyword: _?) => true,

    InstanceCreationExpression(:final keyword?)
        when keyword.type == Keyword.CONST =>
      true,

    PrefixExpression(:final operand) => isConstantExpression(operand),

    SimpleIdentifier() => isConstantIdentifier(expr),

    PrefixedIdentifier(:final identifier) => isConstantIdentifier(identifier),

    // Edge case: `SomeClass.constField` may also parse as a PropertyAccess
    PropertyAccess(:final propertyName) => isConstantIdentifier(propertyName),

    _ => false,
  };
}

bool isConstantIdentifier(SimpleIdentifier id) {
  final element = id.element;

  if (element is VariableElement) {
    return element.isConst ||
        (element.isFinal && element.computeConstantValue() != null);
  }

  if (element is PropertyAccessorElement) {
    return element.variable.isConst;
  }

  return false;
}
