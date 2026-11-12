import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

DartType? inferContextType(Expression node) {
  final parent = node.parent;

  return switch (parent) {
    VariableDeclaration(parent: VariableDeclarationList(:final type?)) =>
      type.type,

    AssignmentExpression(:final leftHandSide) => leftHandSide.staticType,

    NamedArgument(:final correspondingParameter) => resolveParameterContextType(
      correspondingParameter,
      parent,
    ),

    FormalParameterDefaultClause(parent: FormalParameter(:final type?)) =>
      type.type,

    BinaryExpression(:final leftOperand, :final rightOperand) =>
      node == rightOperand ? leftOperand.staticType : rightOperand.staticType,

    ListLiteral() || SetOrMapLiteral() when parent != null =>
      resolveCollectionElementType(parent),

    MapLiteralEntry(:final key, :final value) => resolveMapEntryType(
      parent,
      isKey: node == key,
      isValue: node == value,
    ),

    SwitchCase() => resolveSwitchExpressionType(parent),

    ConstantPattern() => resolvePatternContextType(parent),

    ExpressionFunctionBody() => resolveReturnType(parent),

    ReturnStatement() => resolveReturnType(parent),

    ParenthesizedExpression() => inferContextType(parent),

    _ => null,
  };
}

DartType? resolveParameterContextType(
  FormalParameterElement? parameter,
  AstNode argument,
) {
  if (parameter == null) return null;

  // Edge case: a user-pinned type argument is a real context, only an inferred one is circular
  if (_mentionsTypeParameter(parameter.baseElement.type) &&
      !_hasExplicitTypeArguments(argument)) {
    return null;
  }

  return parameter.type;
}

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

DartType? resolveCollectionElementType(AstNode collectionNode) {
  final typeArguments = resolveCollectionTypeArguments(collectionNode);

  if (typeArguments == null || typeArguments.length != 1) return null;

  return typeArguments.first;
}

DartType? resolveMapEntryType(
  MapLiteralEntry entry, {
  required bool isKey,
  required bool isValue,
}) {
  if (isKey == isValue) return null;

  final typeArguments = resolveCollectionTypeArguments(entry.parent);
  if (typeArguments == null || typeArguments.length != 2) return null;

  return isKey ? typeArguments.first : typeArguments.last;
}

List<DartType?>? resolveCollectionTypeArguments(AstNode? collectionNode) {
  if (collectionNode is! TypedLiteral) return null;

  if (collectionNode.typeArguments?.arguments case final typeArgs?
      when typeArgs.isNotEmpty) {
    return typeArgs.map((t) => t.type).toList();
  }

  // Edge case: the upward-inferred static type would be circular, so use the downward context
  final contextType = inferContextType(collectionNode);
  if (contextType is! InterfaceType) return null;

  return contextType.typeArguments;
}

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

bool isTypeCompatible(DartType contextType, InterfaceElement targetElement) {
  if (contextType is! InterfaceType) return false;

  return contextType.element == targetElement;
}
