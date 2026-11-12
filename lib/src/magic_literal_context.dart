import 'package:analyzer/dart/ast/ast.dart';

bool initialisesADeclaration(Literal literal) {
  // Edge case: in `100 * 1024 * 1024` every literal has a BinaryExpression parent, so walk up
  for (AstNode? node = literal.parent; node != null; node = node.parent) {
    if (node is VariableDeclaration) return true;
    if (node is FormalParameterDefaultClause) return true;
    if (node is ConstructorFieldInitializer) return true;

    final isArithmeticOrGrouping =
        node is BinaryExpression ||
        node is PrefixExpression ||
        node is ParenthesizedExpression;
    if (!isArithmeticOrGrouping) return false;
  }

  return false;
}

bool isInExemptContext(Literal literal) {
  if (_isInsideConstantDeclaration(literal)) return true;

  if (literal.thisOrAncestorOfType<Annotation>() != null) return true;

  return false;
}

bool _isInsideConstantDeclaration(Literal literal) {
  for (AstNode? node = literal.parent; node != null; node = node.parent) {
    if (node is EnumConstantDeclaration) return true;
    if (node is VariableDeclarationList && node.isConst) return true;
    if (node is FieldDeclaration && node.fields.isConst) return true;
    if (node is TopLevelVariableDeclaration && node.variables.isConst) {
      return true;
    }
    // Edge case: `const EdgeInsets.all(17)` still hides what 17 means, so the walk stops here
    if (node is InstanceCreationExpression) return false;
    if (node is FunctionBody) return false;
  }

  return false;
}

bool isArgumentToIgnoredInvocation(Literal literal, Set<String> ignored) {
  if (ignored.isEmpty) return false;

  final parent = literal.parent;
  if (parent is! ArgumentList &&
      !(parent is NamedArgument && parent.parent is ArgumentList)) {
    return false;
  }

  final call = literal.thisOrAncestorOfType<InvocationExpression>();
  final name = switch (call) {
    MethodInvocation() => call.methodName.name,
    _ => null,
  };
  if (name != null && ignored.contains(name)) return true;

  final creation = literal.thisOrAncestorOfType<InstanceCreationExpression>();
  final typeName = creation?.constructorName.type.name.lexeme;
  if (typeName != null && ignored.contains(typeName)) return true;

  // Edge case: a dot shorthand names no type, so the type comes from resolution
  final shorthand = _shorthandTypeName(literal);

  return shorthand != null && ignored.contains(shorthand);
}

String? _shorthandTypeName(Literal literal) {
  for (AstNode? node = literal.parent; node != null; node = node.parent) {
    final type = switch (node) {
      DotShorthandConstructorInvocation() => node.staticType,
      DotShorthandInvocation() => node.staticType,
      DotShorthandPropertyAccess() => node.staticType,
      _ => null,
    };
    if (type != null) return type.element?.name;
    if (node is FunctionBody) break;
  }

  return null;
}
