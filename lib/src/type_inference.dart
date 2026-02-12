import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// Utilities for inferring context types from AST nodes.
///
/// These functions help determine the expected type of an expression based on
/// its usage context (e.g., variable declaration, return statement, collection
/// literal, switch case, etc.).

/// Infers the expected type of an expression from its context.
///
/// Returns the type that the expression is expected to have based on where
/// it appears in the code (e.g., in a variable declaration, assignment,
/// return statement, collection literal, etc.).
///
/// Returns `null` if the context type cannot be determined.
DartType? inferContextType(Expression node) {
  final parent = node.parent;

  return switch (parent) {
    // Variable declaration: `final Type x = value;`
    VariableDeclaration(parent: VariableDeclarationList(:final type?)) =>
      type.type,

    // Assignment: `x = value;`
    AssignmentExpression(:final leftHandSide) => leftHandSide.staticType,

    // Named expression (default parameter, named argument, named argument in call)
    NamedExpression() => inferContextType(parent),

    // Default formal parameter: `{Type value = defaultValue}`
    DefaultFormalParameter(parameter: SimpleFormalParameter(:final type?)) =>
      type.type,

    // Binary expression (comparison): `e == value`
    BinaryExpression(:final leftOperand, :final rightOperand) =>
      node == rightOperand ? leftOperand.staticType : rightOperand.staticType,

    // List/Set literal: `[value]` or `{value}`
    ListLiteral() || SetOrMapLiteral() when parent != null =>
      resolveCollectionElementType(parent),

    // Switch case: `case value:`
    SwitchCase() => resolveSwitchExpressionType(parent),

    // Constant pattern (switch expression): `value =>`
    ConstantPattern() => resolvePatternContextType(parent),

    // Expression function body: `Type fn() => value;`
    ExpressionFunctionBody() => resolveReturnType(parent),

    // Return statement: `return value;`
    ReturnStatement() => resolveReturnType(parent),

    // Parenthesized expression: pass through to parent
    ParenthesizedExpression() => inferContextType(parent),

    _ => null,
  };
}

/// Resolves the element type from a collection literal.
///
/// For example, given `List<String>`, returns `String`.
/// For `Set<int>`, returns `int`.
DartType? resolveCollectionElementType(AstNode collectionNode) {
  // Get the static type of the collection
  final collectionType = switch (collectionNode) {
    ListLiteral(:final staticType) ||
    SetOrMapLiteral(:final staticType) => staticType,
    _ => null,
  };

  if (collectionType is! InterfaceType) return null;

  // Extract the element type from List<T>, Set<T>, or Map<K,V>
  final typeArgs = collectionType.typeArguments;
  if (typeArgs.isEmpty) return null;

  return typeArgs.first; // For List/Set, this is the element type
}

/// Resolves the type of the expression being switched on.
///
/// Walks up the AST to find the enclosing switch statement or expression
/// and returns the type of the switched expression.
DartType? resolveSwitchExpressionType(AstNode node) {
  AstNode? current = node;
  while (current != null) {
    if (current is SwitchStatement) {
      return current.expression.staticType;
    }
    if (current is SwitchExpression) {
      return current.expression.staticType;
    }
    current = current.parent;
  }
  return null;
}

/// Resolves the expected type for a pattern from its context.
///
/// For switch pattern cases, returns the type of the switch expression.
DartType? resolvePatternContextType(AstNode node) {
  AstNode? current = node;
  while (current != null) {
    if (current is SwitchPatternCase) {
      return resolveSwitchExpressionType(current);
    }
    if (current is SwitchExpressionCase) {
      return resolveSwitchExpressionType(current);
    }
    current = current.parent;
  }
  return null;
}

/// Resolves the expected return type from a function or method.
///
/// Walks up the AST to find the enclosing function/method declaration
/// and returns its declared return type.
DartType? resolveReturnType(AstNode node) {
  AstNode? current = node;
  while (current != null) {
    if (current is FunctionDeclaration && current.returnType != null) {
      return current.returnType!.type;
    }
    if (current is MethodDeclaration && current.returnType != null) {
      return current.returnType!.type;
    }
    if (current is FunctionExpression) {
      // For function expressions, look at the parent context
      final parent = current.parent;
      if (parent is VariableDeclaration) {
        final varDecl = parent.parent;
        if (varDecl is VariableDeclarationList && varDecl.type != null) {
          return varDecl.type!.type;
        }
      }
    }
    current = current.parent;
  }
  return null;
}

/// Checks if a context type is compatible with a given interface element.
///
/// Returns `true` if the [contextType] is an interface type whose element
/// matches the [targetElement], ignoring nullability.
///
/// Returns `false` for non-interface types (including `dynamic`).
bool isTypeCompatible(DartType contextType, InterfaceElement targetElement) {
  // Don't suggest shorthands for non-interface types (including dynamic)
  if (contextType is! InterfaceType) return false;

  // Check if the context type matches the target type (ignoring nullability)
  return contextType.element == targetElement;
}
