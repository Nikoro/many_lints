import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

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

  static const _defaultClasses = {
    'EdgeInsets',
    'BorderRadius',
    'Radius',
    'Border',
  };

  // Edge case: rule instances are reused across package roots, so config is never cached.
  Set<String> get _classes =>
      rule.config.nameSetOption('classes', defaultValue: _defaultClasses);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final typeName = node.constructorName.type;
    final typeElement = typeName.element;
    if (typeElement is! InterfaceElement) return;

    final className = typeName.name.lexeme;
    if (!_classes.contains(className)) return;
    if (!_isUsedAsArgument(node)) return;

    final contextType = _getContextType(node);
    if (contextType == null) return;

    final name = node.constructorName.name?.name ?? 'new';
    if (!_shorthandResolves(contextType, typeElement, name)) return;

    rule.reportAtNode(node.constructorName);
  }

  // Edge case: `EdgeInsets.symmetric(...)` can reach the AST as a method invocation.
  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    if (target is! SimpleIdentifier) return;

    final className = target.name;
    if (!_classes.contains(className)) return;
    if (!_isUsedAsArgument(node)) return;

    final staticType = node.staticType;
    if (staticType is! InterfaceType) return;

    final typeElement = staticType.element;
    if (typeElement.name != className) return;

    final contextType = _getContextType(node);
    if (contextType == null) return;

    final name = node.methodName.name;
    if (!_shorthandResolves(contextType, typeElement, name)) return;

    rule.reportAtToken(target.token);
  }

  bool _isUsedAsArgument(Expression node) {
    AstNode? current = node.parent;

    while (current != null) {
      switch (current) {
        case NamedArgument() ||
            ArgumentList() ||
            ListLiteral() ||
            SetOrMapLiteral():
          return true;
        case ParenthesizedExpression():
          current = current.parent;
        default:
          return false;
      }
    }

    return false;
  }

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

  // Edge case: the literal's inferred type comes from the element a shorthand would replace.
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
