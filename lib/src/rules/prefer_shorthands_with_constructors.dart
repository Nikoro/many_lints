import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

/// Suggests using dot shorthand constructor invocations for specific classes.
///
/// **Supported classes:** EdgeInsets, BorderRadius, Radius, Border
///
/// This rule only works for arguments (both positional and named).
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
class PreferShorthandsWithConstructors extends AnalysisRule {
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
  void registerNodeProcessors(
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
  /// To customize this list for your project:
  /// 1. Fork the package or create a custom rule
  /// 2. Modify this set to include your desired classes
  ///
  /// Common candidates for addition:
  /// - 'Alignment' (e.g., Alignment.center -> .center)
  /// - 'AlignmentDirectional' (e.g., AlignmentDirectional.topStart -> .topStart)
  /// - 'EdgeInsetsGeometry' (base class for EdgeInsets)
  /// - 'TextStyle' (if using const constructors)
  ///
  /// Note: Future versions may support configuration via analysis_options.yaml
  static const _defaultClasses = {
    'EdgeInsets',
    'BorderRadius',
    'Radius',
    'Border',
  };

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // Get the class element
    final typeName = node.constructorName.type;
    final typeElement = typeName.element;
    if (typeElement is! InterfaceElement) return;

    final className = typeName.name.lexeme;

    // Check if this is one of the configured classes
    if (!_defaultClasses.contains(className)) return;

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
    if (!_defaultClasses.contains(className)) return;

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
        case NamedExpression():
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
        case NamedExpression():
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

  /// Checks if the context type is compatible with the constructor's class.
  bool _isTypeCompatible(DartType contextType, InterfaceElement classElement) {
    // Don't suggest shorthands for non-interface types (including dynamic)
    if (contextType is! InterfaceType) return false;

    // Check if the context type matches the class type (ignoring nullability)
    return contextType.element == classElement;
  }
}
