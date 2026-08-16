/// Shared machinery for `no_magic_number` and `no_magic_string`.
///
/// Both rules ask the same question — is this literal a value the reader has
/// to decode, or is it already named? — and both answer it by looking at where
/// the literal sits rather than at the literal itself. Keeping that walk here
/// means the two rules differ only in which literals they consider.
library;

import 'package:analyzer/dart/ast/ast.dart';

/// Whether [literal] is already named by the declaration it initialises.
///
/// `const maxRetries = 3;` puts the number one token away from its name, which
/// is exactly what these rules ask for — reporting it would demand a constant
/// initialised by another constant, forever.
bool initialisesADeclaration(Literal literal) {
  // Walked rather than checked directly, because an initialiser is routinely
  // an *expression* over literals: `maximumStoredBytes = 100 * 1024 * 1024` is
  // as named as `timeout = 30`, but each of its three literals has a
  // `BinaryExpression` for a parent.
  for (AstNode? node = literal.parent; node != null; node = node.parent) {
    if (node is VariableDeclaration) return true;
    // A default value names the parameter it belongs to. Analyzer 14 spells
    // this `FormalParameterDefaultClause`; `DefaultFormalParameter` is gone.
    if (node is FormalParameterDefaultClause) return true;
    // A field initialised in a constructor initialiser list, or via `this.x`.
    if (node is ConstructorFieldInitializer) return true;

    // Only arithmetic and grouping are transparent. Anything else means the
    // literal is doing work of its own rather than spelling out one value.
    final transparent =
        node is BinaryExpression ||
        node is PrefixExpression ||
        node is ParenthesizedExpression;
    if (!transparent) return false;
  }

  return false;
}

/// Whether [literal] sits somewhere a name would add nothing.
///
/// The exemptions are what make these rules usable rather than exhausting:
/// each is a place where the surrounding code already states what the value
/// means, so extracting a constant would only add indirection.
bool isInExemptContext(Literal literal) {
  // Inside a `const` or `enum` declaration the literal IS the definition of a
  // named thing — this is the shape the rule asks people to move towards.
  if (_isInsideConstantDeclaration(literal)) return true;

  // An annotation's arguments are metadata, fixed at the declaration site.
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
    // A const constructor invocation is not itself a definition: `const
    // EdgeInsets.all(17)` still hides what 17 means, and stopping the walk
    // here would exempt most Flutter layout code by accident.
    if (node is InstanceCreationExpression) return false;
    if (node is FunctionBody) return false;
  }

  return false;
}

/// Whether [literal] is an argument to a call this project cannot name.
///
/// Matched on the *method* name rather than the resolved element, because the
/// point is the reader's experience at the call site: `substring(0, 4)` reads
/// fine, and no constant would improve it.
bool isArgumentToIgnoredInvocation(Literal literal, Set<String> ignored) {
  if (ignored.isEmpty) return false;

  // A positional argument sits directly in the list; a named one is wrapped in
  // a `NamedArgument` (analyzer 14's spelling of the old `NamedExpression`).
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

  // A dot shorthand (`padding: const .only(top: 12)`) writes no type name at
  // all, so the spelling above cannot see it — and in Flutter code that is the
  // *common* form. The type comes from resolution instead. Without this, the
  // layout exemption missed 202 of the 416 spacing literals it was written for.
  final shorthand = _shorthandTypeName(literal);

  return shorthand != null && ignored.contains(shorthand);
}

/// The name of the type a dot shorthand around [literal] resolves to.
String? _shorthandTypeName(Literal literal) {
  for (AstNode? node = literal.parent; node != null; node = node.parent) {
    final type = switch (node) {
      DotShorthandConstructorInvocation() => node.staticType,
      DotShorthandInvocation() => node.staticType,
      DotShorthandPropertyAccess() => node.staticType,
      _ => null,
    };
    if (type != null) return type.element?.name;
    // Stop once past the invocation this literal is an argument to: a
    // shorthand further out belongs to a different call. The walk passes
    // through the ArgumentList first, so that is not the boundary.
    if (node is FunctionBody) break;
  }

  return null;
}
