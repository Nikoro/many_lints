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

    // Named argument: `argument: value`
    NamedArgument(:final correspondingParameter) => resolveParameterContextType(
      correspondingParameter,
      parent,
    ),

    // Default value clause: `{Type value = defaultValue}`
    FormalParameterDefaultClause(parent: FormalParameter(:final type?)) =>
      type.type,

    // Binary expression (comparison): `e == value`
    BinaryExpression(:final leftOperand, :final rightOperand) =>
      node == rightOperand ? leftOperand.staticType : rightOperand.staticType,

    // List/Set literal: `[value]` or `{value}`
    ListLiteral() || SetOrMapLiteral() when parent != null =>
      resolveCollectionElementType(parent),

    // Map entry: `{key: value}` — which type argument applies depends on
    // whether the expression is the key or the value.
    MapLiteralEntry(:final key, :final value) => resolveMapEntryType(
      parent,
      isKey: node == key,
      isValue: node == value,
    ),

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

/// Resolves the context type contributed by a formal parameter.
///
/// Returns `null` when the parameter's *declared* type mentions a type
/// variable, because then the type the analyzer reports has been inferred
/// upward from this very argument rather than imposed on it.
/// `Box<T>({List<T> items})` invoked as `Box(items: [MyEnum.first])` reports
/// `List<MyEnum>` only because `T` was solved from the element, so a dot
/// shorthand there would have no context type to resolve against and would
/// not compile.
DartType? resolveParameterContextType(
  FormalParameterElement? parameter,
  AstNode argument,
) {
  if (parameter == null) return null;

  // A type variable that the *user* pinned with an explicit type argument is a
  // real context: `Box<MyEnum>(items: [.first])` compiles. Only an inferred
  // one is circular.
  if (_mentionsTypeParameter(parameter.baseElement.type) &&
      !_hasExplicitTypeArguments(argument)) {
    return null;
  }

  return parameter.type;
}

/// Whether the invocation enclosing [argument] pins its type arguments
/// explicitly rather than leaving them to inference.
bool _hasExplicitTypeArguments(AstNode argument) {
  final invocation = argument.parent?.parent;

  return switch (invocation) {
    MethodInvocation(:final typeArguments) => typeArguments != null,
    FunctionExpressionInvocation(:final typeArguments) => typeArguments != null,
    InstanceCreationExpression(:final constructorName) =>
      constructorName.type.typeArguments != null,
    _ => false,
  };
}

/// Whether [type] mentions a type variable anywhere in its structure.
bool _mentionsTypeParameter(DartType type) {
  if (type is TypeParameterType) return true;

  if (type is InterfaceType) {
    return type.typeArguments.any(_mentionsTypeParameter);
  }

  if (type is FunctionType) {
    return _mentionsTypeParameter(type.returnType) ||
        type.formalParameters.any((p) => _mentionsTypeParameter(p.type));
  }

  if (type is RecordType) {
    return type.positionalFields.any((f) => _mentionsTypeParameter(f.type)) ||
        type.namedFields.any((f) => _mentionsTypeParameter(f.type));
  }

  return false;
}

/// Resolves the element type from a collection literal.
///
/// For example, given `List<String>`, returns `String`.
/// For `Set<int>`, returns `int`.
///
/// Only a genuine *downward* context counts. A literal's `staticType` cannot be
/// trusted here: when the literal has no context of its own, the analyzer
/// infers its type upward from the elements themselves, so
/// `equals([MyEnum.first])` would report `List<MyEnum>` and any element would
/// trivially "match" its own context. Dot shorthands require a downward context
/// type, so this returns `null` unless the element type comes from an explicit
/// type argument or from the collection's own context type.
DartType? resolveCollectionElementType(AstNode collectionNode) {
  final typeArguments = resolveCollectionTypeArguments(collectionNode);

  // A list or set contributes exactly one type argument. Two means the literal
  // is a map, whose entries are handled by [resolveMapEntryType] instead.
  if (typeArguments == null || typeArguments.length != 1) return null;

  return typeArguments.first;
}

/// Resolves the context type of the key or value half of a map entry.
///
/// `{MyEnum.first: 'a'}` under a `Map<MyEnum, String>` context gives the key
/// `MyEnum` and the value `String`. Returns `null` when the entry belongs to a
/// literal without a genuine downward context.
DartType? resolveMapEntryType(
  MapLiteralEntry entry, {
  required bool isKey,
  required bool isValue,
}) {
  if (isKey == isValue) return null; // Neither half, or ambiguous.

  final typeArguments = resolveCollectionTypeArguments(entry.parent);
  if (typeArguments == null || typeArguments.length != 2) return null;

  return isKey ? typeArguments.first : typeArguments.last;
}

/// Resolves the type arguments that give a collection literal its element
/// types, using only a genuine *downward* context.
///
/// A literal's `staticType` cannot be trusted here: when the literal has no
/// context of its own, the analyzer infers its type upward from the elements
/// themselves, so `equals([MyEnum.first])` would report `List<MyEnum>` and any
/// element would trivially "match" its own context. Dot shorthands require a
/// downward context type, so this returns `null` unless the types come from an
/// explicit type argument or from the literal's own context type.
List<DartType?>? resolveCollectionTypeArguments(AstNode? collectionNode) {
  if (collectionNode is! TypedLiteral) return null;

  // An explicit type argument is written by the user, so it is a real context:
  // `<MyEnum>[MyEnum.first]` accepts `<MyEnum>[.first]`.
  if (collectionNode.typeArguments?.arguments case final typeArgs?
      when typeArgs.isNotEmpty) {
    return typeArgs.map((t) => t.type).toList();
  }

  // Otherwise the types have to come from the literal's own downward context,
  // not from its upward-inferred static type.
  final contextType = inferContextType(collectionNode);
  if (contextType is! InterfaceType) return null;

  return contextType.typeArguments;
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

/// Returns the element type of an `Iterable`-like [type], or `null`.
///
/// `List<int>`, `Set<int>` and `Iterable<int>` all carry the element type as
/// their first type argument, so that is used directly. A custom subtype such
/// as `class Ints extends ListBase<int>` has no type arguments of its own, so
/// the element type has to be recovered from the `Iterable<E>` in its
/// supertypes.
DartType? iterableElementType(InterfaceType type) {
  if (type.typeArguments.isNotEmpty) {
    return type.typeArguments.first;
  }

  for (final supertype in type.element.allSupertypes) {
    if (supertype.element.name == 'Iterable' &&
        supertype.typeArguments.isNotEmpty) {
      return supertype.typeArguments.first;
    }
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
