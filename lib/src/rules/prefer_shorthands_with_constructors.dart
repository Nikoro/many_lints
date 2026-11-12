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

    // Verify the shorthand would resolve against the context type
    final name = node.constructorName.name?.name ?? 'new';
    if (!_shorthandResolves(contextType, typeElement, name)) return;

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

    // Verify the shorthand would resolve against the context type
    final name = node.methodName.name;
    if (!_shorthandResolves(contextType, typeElement, name)) return;

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
  /// For an argument this is the parameter's declared type, which is what a
  /// dot shorthand resolves against; the expression's own type would claim a
  /// shorthand exists when the parameter is a supertype that lacks it.
  DartType? _getContextType(Expression node) {
    final expression = _outermost(node);
    return switch (expression.parent) {
      final NamedArgument named => named.correspondingParameter?.type,
      ArgumentList() => expression.correspondingParameter?.type,
      VariableDeclaration(parent: VariableDeclarationList(:final type?)) =>
        type.type,
      final TypedLiteral literal => _elementContextType(literal),
      _ => null,
    };
  }

  /// The type a list or set literal's elements are inferred against: its
  /// explicit type argument, else the element type of the literal's own
  /// context. The literal's inferred type does not count, since
  /// `final paddings = [EdgeInsets.all(8)]` infers `List<EdgeInsets>` from
  /// the very element a shorthand would replace.
  DartType? _elementContextType(TypedLiteral literal) {
    final explicit = literal.typeArguments?.arguments;
    if (explicit != null) {
      return explicit.length == 1 ? explicit.first.type : null;
    }
    final context = _getContextType(literal);
    if (context is! InterfaceType || context.typeArguments.length != 1) {
      return null;
    }
    return context.typeArguments.first;
  }

  /// The argument expression itself, past any wrapping parentheses.
  Expression _outermost(Expression node) {
    var current = node;
    for (
      var parent = current.parent;
      parent is ParenthesizedExpression;
      parent = parent.parent
    ) {
      current = parent;
    }
    return current;
  }

  /// Whether `.name(...)` would resolve against [contextType] to the same
  /// constructor or static member: the same class, or a supertype whose
  /// factory of that name redirects to this class's constructor (Flutter's
  /// `EdgeInsetsGeometry.all = EdgeInsets.all`). A supertype's static method
  /// or non-redirecting factory may build something else, and its
  /// `EdgeInsetsGeometry.only` lacks `EdgeInsetsDirectional.only`'s `start`.
  bool _shorthandResolves(
    DartType contextType,
    InterfaceElement classElement,
    String name,
  ) {
    if (contextType is! InterfaceType) return false;
    final context = contextType.element;
    if (context == classElement) return true;
    final target = _constructorNamed(classElement, name);
    final factory = _constructorNamed(context, name);
    if (target == null || factory == null || !factory.isFactory) return false;
    final visited = <ConstructorElement>{};
    for (
      var redirected = factory.redirectedConstructor?.baseElement;
      redirected != null && visited.add(redirected);
      redirected = redirected.redirectedConstructor?.baseElement
    ) {
      if (redirected == target.baseElement) return true;
    }
    return false;
  }

  ConstructorElement? _constructorNamed(InterfaceElement type, String name) {
    for (final constructor in type.constructors) {
      if ((constructor.name ?? 'new') == name) return constructor;
    }
    return null;
  }
}
