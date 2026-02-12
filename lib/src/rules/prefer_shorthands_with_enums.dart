import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

/// Suggests using dot shorthands instead of explicit enum prefixes.
///
/// **BAD:**
/// ```dart
/// enum MyEnum { first, second }
/// void fn(MyEnum? e) {
///   switch (e) {
///     case MyEnum.first:  // LINT
///       print(e);
///   }
///   final MyEnum another = MyEnum.first; // LINT
///   if (e == MyEnum.first) {} // LINT
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// enum MyEnum { first, second }
/// void fn(MyEnum? e) {
///   switch (e) {
///     case .first:
///       print(e);
///   }
///   final MyEnum another = .first;
///   if (e == .first) {}
/// }
/// ```
class PreferShorthandsWithEnums extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_shorthands_with_enums',
    'Prefer dot shorthands instead of explicit enum prefixes.',
    correctionMessage: 'Try removing the enum prefix.',
  );

  PreferShorthandsWithEnums()
    : super(
        name: 'prefer_shorthands_with_enums',
        description: 'Suggests using dot shorthands instead of explicit enum prefixes.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addPrefixedIdentifier(this, visitor);
    registry.addPropertyAccess(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferShorthandsWithEnums rule;

  _Visitor(this.rule);

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _checkEnumReference(node, node.prefix, node.identifier);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.target case final target? when node.propertyName != null) {
      _checkEnumReference(node, target, node.propertyName);
    }
  }

  void _checkEnumReference(Expression node, Expression prefixExpression, SimpleIdentifier identifier) {
    // The static type of the full expression should be an enum type
    final nodeType = node.staticType;
    if (nodeType is! InterfaceType) return;

    final enumElement = nodeType.element;
    if (enumElement is! EnumElement) return;

    // Verify the prefix is a simple identifier matching the enum name
    if (prefixExpression is! SimpleIdentifier) return;
    if (prefixExpression.name != enumElement.name) return;

    // Check if context type makes the enum type inferable
    final contextType = _getContextType(node);
    if (contextType == null) return;

    // The shorthand is valid when the context type matches the enum type
    if (!_isEnumTypeCompatible(contextType, enumElement)) return;

    // Report the lint
    rule.reportAtNode(node);
  }

  /// Gets the expected type from the context where the expression appears.
  DartType? _getContextType(Expression node) {
    final parent = node.parent;

    return switch (parent) {
      // Variable declaration: `final MyEnum x = MyEnum.first;`
      VariableDeclaration(parent: VariableDeclarationList(:final type?)) => type.type,

      // Assignment: `x = MyEnum.first;`
      AssignmentExpression(:final leftHandSide) => leftHandSide.staticType,

      // Named expression (default parameter, named argument, named argument in call)
      NamedExpression() => _getContextType(parent),

      // Default formal parameter: `{MyEnum value = MyEnum.first}`
      DefaultFormalParameter(parameter: SimpleFormalParameter(:final type?)) => type.type,

      // Binary expression (comparison): `e == MyEnum.first`
      BinaryExpression(:final leftOperand, :final rightOperand) =>
        node == rightOperand ? leftOperand.staticType : rightOperand.staticType,

      // List/Set literal: `[MyEnum.first]` or `{MyEnum.first}`
      ListLiteral() || SetOrMapLiteral() when parent != null => _getCollectionElementType(parent),

      // Switch case: `case MyEnum.first:`
      SwitchCase() => _getSwitchExpressionType(parent),

      // Constant pattern (switch expression): `MyEnum.first =>`
      ConstantPattern() => _getPatternContextType(parent),

      // Expression function body: `MyEnum getEnum() => MyEnum.first;`
      ExpressionFunctionBody() => _getReturnType(parent),

      // Return statement: `return MyEnum.first;`
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
      ListLiteral(:final staticType) || SetOrMapLiteral(:final staticType) => staticType,
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

  /// Checks if the context type is compatible with the enum type.
  bool _isEnumTypeCompatible(DartType contextType, EnumElement enumElement) {
    // Get the base type, ignoring nullability
    final baseType = contextType is InterfaceType ? contextType : null;

    if (baseType == null) return false;

    // Check if the context type matches the enum type (ignoring nullability)
    return baseType.element == enumElement;
  }
}
