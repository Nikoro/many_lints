import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';

/// Returns `true` if [expression] is a compile-time constant.
bool isConstantExpression(Expression expression) {
  var expr = expression;
  while (expr is ParenthesizedExpression) {
    expr = expr.expression;
  }

  return switch (expr) {
    // Literals: 1, 'hello', true, false, null
    IntegerLiteral() => true,
    DoubleLiteral() => true,
    SimpleStringLiteral() => true,
    BooleanLiteral() => true,
    NullLiteral() => true,

    // const [1, 2] or const {1, 2}
    TypedLiteral(constKeyword: _?) => true,

    // const MyClass()
    InstanceCreationExpression(:final keyword?)
        when keyword.type == Keyword.CONST =>
      true,

    // Prefix expression on constant: -1, !true
    PrefixExpression(:final operand) => isConstantExpression(operand),

    // Simple identifier: const x = 10; / static const field
    SimpleIdentifier() => isConstantIdentifier(expr),

    // Prefixed identifier: SomeClass.constField
    PrefixedIdentifier(:final identifier) => isConstantIdentifier(identifier),

    // Property access: SomeClass.constField (alternative AST shape)
    PropertyAccess(:final propertyName) => isConstantIdentifier(propertyName),

    _ => false,
  };
}

/// Returns `true` if the identifier refers to a const variable or field.
bool isConstantIdentifier(SimpleIdentifier id) {
  final element = id.element;

  // Local const / final variables
  if (element is VariableElement) {
    return element.isConst ||
        (element.isFinal && element.computeConstantValue() != null);
  }

  // Top-level / static const fields (resolved as synthetic getter)
  if (element is PropertyAccessorElement) {
    return element.variable.isConst;
  }

  return false;
}
