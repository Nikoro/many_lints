import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Suggests using dot shorthand constructor invocations for specific classes.
///
/// **Default classes:** EdgeInsets, BorderRadius, Radius, Border
///
/// This rule only works for arguments (both positional and named).
///
/// **Configuration** (`many_lints.yaml`):
///
/// ```yaml
/// rules:
///   prefer_shorthands_with_constructors:
///     classes: [EdgeInsets, BorderRadius]   # replaces the defaults
///     additional_classes: [Alignment]       # extends whichever list applies
/// ```
///
/// **BAD:**
/// ```dart
/// Padding(
///   padding: EdgeInsets.symmetric(  // LINT
///     horizontal: 16,
///     vertical: 12,
///   ),
/// )
///
/// BoxDecoration(
///   border: Border.all(  // LINT
///     color: Colors.red,
///     width: 2,
///   ),
///   borderRadius: BorderRadius.circular(18),  // LINT
/// )
/// ```
///
/// **GOOD:**
/// ```dart
/// Padding(
///   padding: .symmetric(
///     horizontal: 16,
///     vertical: 12,
///   ),
/// )
///
/// BoxDecoration(
///   border: .all(
///     color: Colors.red,
///     width: 2,
///   ),
///   borderRadius: .circular(18),
/// )
/// ```
class PreferShorthandsWithConstructors extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_shorthands_with_constructors',
    'Prefer dot shorthands instead of explicit class instantiations.',
    correctionMessage: 'Try using the dot shorthand constructor.',
  );

  PreferShorthandsWithConstructors()
    : super(
        name: 'prefer_shorthands_with_constructors',
        description:
            'Suggests using dot shorthand constructor invocations for the configured list of classes.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferShorthandsWithConstructors rule;

  _Visitor(this.rule);

  /// Default list of classes that should use dot shorthands.
  ///
  /// Configurable per project — `classes` replaces this list and
  /// `additional_classes` extends it. Common additions are `Alignment`,
  /// `AlignmentDirectional`, `EdgeInsetsGeometry` and `TextStyle`.
  static const _defaultClasses = {
    'EdgeInsets',
    'BorderRadius',
    'Radius',
    'Border',
  };

  /// The classes to report, resolved against this file's configuration.
  ///
  /// Read per visit rather than cached in the constructor: rule instances are
  /// long-lived singletons reused across package roots, so caching here would
  /// leak one package's configuration into another's analysis.
  Set<String> get _classes =>
      rule.config.nameSetOption('classes', defaultValue: _defaultClasses);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // Get the class element
    final typeName = node.constructorName.type;
    final typeElement = typeName.element;
    if (typeElement is! InterfaceElement) return;

    final className = typeName.name.lexeme;

    // Check if this is one of the configured classes
    if (!_classes.contains(className)) return;

    // Check if this is used as an argument
    if (!_isUsedAsArgument(node)) return;

    // Check if the type can be inferred from context
    final contextType = _getContextType(node);
    if (contextType == null) return;

    // Verify the context type matches the constructor's class
    if (!_isTypeCompatible(contextType, typeElement)) return;

    // Report the lint
    rule.reportAtNode(node.constructorName);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Check if this is a named constructor invocation (e.g., EdgeInsets.symmetric)
    // These can appear as method invocations in the AST
    if (node.target is! SimpleIdentifier) return;

    final target = node.target as SimpleIdentifier;
    final className = target.name;

    // Check if this is one of the configured classes
    if (!_classes.contains(className)) return;

    // Check if this is used as an argument
    if (!_isUsedAsArgument(node)) return;

    // Get the static type to verify it's actually a constructor call
    final staticType = node.staticType;
    if (staticType is! InterfaceType) return;

    final typeElement = staticType.element;
    if (typeElement.name != className) return;

    // Check if the type can be inferred from context
    final contextType = _getContextType(node);
    if (contextType == null) return;

    // Verify the context type matches the constructor's class
    if (!_isTypeCompatible(contextType, typeElement)) return;

    // Report the lint - report at the target (class name) and method name
    // We need to cover both parts: "EdgeInsets" + "." + "symmetric"
    rule.reportAtToken(target.token);
  }

  /// Checks if the instance creation is used as an argument.
  bool _isUsedAsArgument(Expression node) {
    AstNode? current = node.parent;

    while (current != null) {
      switch (current) {
        case NamedArgument():
          return true;
        case ArgumentList():
          return true;
        case ListLiteral():
        case SetOrMapLiteral():
          return true;
        case ParenthesizedExpression():
          // Continue checking parent
          current = current.parent;
        default:
          return false;
      }
    }

    return false;
  }

  /// Gets the expected type from the context where the expression appears.
  ///
  /// This uses a pragmatic approach: for arguments, it returns the static type
  /// of the expression itself rather than trying to infer from parent context.
  DartType? _getContextType(Expression node) {
    AstNode? current = node.parent;

    while (current != null) {
      switch (current) {
        case NamedArgument():
        case ArgumentList():
          // For arguments, use the static type of the expression
          // This is a pragmatic approach that works for most cases
          return node.staticType;
        case ListLiteral():
        case SetOrMapLiteral():
          return _getCollectionElementType(current);
        case ParenthesizedExpression():
          // Continue checking parent
          current = current.parent;
          continue;
        default:
          return null;
      }
    }

    return null;
  }

  /// Gets the element type from a collection literal's context.
  DartType? _getCollectionElementType(AstNode collectionNode) {
    final collectionType = switch (collectionNode) {
      ListLiteral(:final staticType) ||
      SetOrMapLiteral(:final staticType) => staticType,
      _ => null,
    };

    if (collectionType is! InterfaceType) return null;

    final typeArgs = collectionType.typeArguments;
    if (typeArgs.isEmpty) return null;

    return typeArgs.first;
  }

  /// Checks if the context type is compatible with the constructor's class.
  bool _isTypeCompatible(DartType contextType, InterfaceElement classElement) {
    if (contextType is! InterfaceType) return false;
    return contextType.element == classElement;
  }
}
