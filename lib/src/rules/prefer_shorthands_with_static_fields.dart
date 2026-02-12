import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

/// Suggests using dot shorthands instead of explicit class prefixes for static fields.
///
/// **BAD:**
/// ```dart
/// class SomeClass {
///   final String value;
///   const SomeClass(this.value);
///   static const first = SomeClass('first');
///   static const second = SomeClass('second');
/// }
///
/// void fn(SomeClass? e) {
///   switch (e) {
///     case SomeClass.first:  // LINT
///       print(e);
///   }
///   final SomeClass another = SomeClass.first; // LINT
///   if (e == SomeClass.first) {} // LINT
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// class SomeClass {
///   final String value;
///   const SomeClass(this.value);
///   static const first = SomeClass('first');
///   static const second = SomeClass('second');
/// }
///
/// void fn(SomeClass? e) {
///   switch (e) {
///     case .first:
///       print(e);
///   }
///   final SomeClass another = .first;
///   if (e == .first) {}
/// }
/// ```
class PreferShorthandsWithStaticFields extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_shorthands_with_static_fields',
    'Prefer dot shorthands instead of explicit class prefixes.',
    correctionMessage: 'Try removing the prefix.',
  );

  PreferShorthandsWithStaticFields()
    : super(
        name: 'prefer_shorthands_with_static_fields',
        description:
            'Suggests using dot shorthands instead of explicit class prefixes for static fields.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addPrefixedIdentifier(this, visitor);
    registry.addPropertyAccess(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferShorthandsWithStaticFields rule;

  _Visitor(this.rule);

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _checkStaticFieldReference(node, node.prefix, node.identifier);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.target case final target?) {
      _checkStaticFieldReference(node, target, node.propertyName);
    }
  }

  void _checkStaticFieldReference(
    Expression node,
    Expression prefixExpression,
    SimpleIdentifier identifier,
  ) {
    // The static type of the full expression
    final nodeType = node.staticType;
    if (nodeType is! InterfaceType) return;

    // Get the field element
    final element = identifier.element;
    if (element is! PropertyAccessorElement) return;

    // Check if it's a static field/getter
    if (!element.isStatic) return;

    // Get the class that declares this static field
    final enclosingElement = element.enclosingElement;
    if (enclosingElement is! InterfaceElement) return;

    // Skip enums - they have their own rule (prefer_shorthands_with_enums)
    if (enclosingElement is EnumElement) return;

    // Verify the prefix is a simple identifier matching the class name
    if (prefixExpression is! SimpleIdentifier) return;
    if (prefixExpression.name != enclosingElement.name) return;

    // The static field's type should match the class it's declared in
    final fieldType = element.returnType;
    if (fieldType is! InterfaceType) return;
    if (fieldType.element != enclosingElement) return;

    // Check if context type makes the field type inferable
    final contextType = _getContextType(node);
    if (contextType == null) return;

    // The shorthand is valid when the context type matches the field type
    if (!_isTypeCompatible(contextType, enclosingElement)) return;

    // Report the lint
    rule.reportAtNode(node);
  }

  /// Gets the expected type from the context where the expression appears.
  DartType? _getContextType(Expression node) {
    final parent = node.parent;

    return switch (parent) {
      // Variable declaration: `final SomeClass x = SomeClass.first;`
      VariableDeclaration(parent: VariableDeclarationList(:final type?)) =>
        type.type,

      // Assignment: `x = SomeClass.first;`
      AssignmentExpression(:final leftHandSide) => leftHandSide.staticType,

      // Named expression (default parameter, named argument, named argument in call)
      NamedExpression() => _getContextType(parent),

      // Default formal parameter: `{SomeClass value = SomeClass.first}`
      DefaultFormalParameter(parameter: SimpleFormalParameter(:final type?)) =>
        type.type,

      // Binary expression (comparison): `e == SomeClass.first`
      BinaryExpression(:final leftOperand, :final rightOperand) =>
        node == rightOperand ? leftOperand.staticType : rightOperand.staticType,

      // List/Set literal: `[SomeClass.first]` or `{SomeClass.first}`
      ListLiteral() || SetOrMapLiteral() when parent != null =>
        _getCollectionElementType(parent),

      // Switch case: `case SomeClass.first:`
      SwitchCase() => _getSwitchExpressionType(parent),

      // Constant pattern (switch expression): `SomeClass.first =>`
      ConstantPattern() => _getPatternContextType(parent),

      // Expression function body: `SomeClass getClass() => SomeClass.first;`
      ExpressionFunctionBody() => _getReturnType(parent),

      // Return statement: `return SomeClass.first;`
      ReturnStatement() => _getReturnType(parent),

      // Parenthesized expression: pass through to parent
      ParenthesizedExpression() => _getContextType(parent),

      _ => null,
    };
  }

  /// Gets the element type from a collection literal's context.
  DartType? _getCollectionElementType(AstNode collectionNode) {
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

  /// Gets the type of the switch expression.
  DartType? _getSwitchExpressionType(AstNode node) {
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

  /// Gets the matched value type for a pattern.
  DartType? _getPatternContextType(AstNode node) {
    AstNode? current = node;
    while (current != null) {
      if (current is SwitchPatternCase) {
        return _getSwitchExpressionType(current);
      }
      if (current is SwitchExpressionCase) {
        return _getSwitchExpressionType(current);
      }
      current = current.parent;
    }
    return null;
  }

  /// Gets the return type from a function body.
  DartType? _getReturnType(AstNode node) {
    AstNode? current = node;
    while (current != null) {
      if (current is FunctionDeclaration && current.returnType != null) {
        return current.returnType!.type;
      }
      if (current is MethodDeclaration && current.returnType != null) {
        return current.returnType!.type;
      }
      if (current is FunctionExpression) {
        // For function expressions, we need to look at the parent context
        // This is more complex and might not always be reliable
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

  /// Checks if the context type is compatible with the class type.
  bool _isTypeCompatible(DartType contextType, InterfaceElement classElement) {
    // Get the base type, ignoring nullability
    final baseType = contextType is InterfaceType ? contextType : null;

    if (baseType == null) return false;

    // Check if the context type matches the class type (ignoring nullability)
    return baseType.element == classElement;
  }
}
