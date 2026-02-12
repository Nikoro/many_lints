import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

/// Suggests returning dot shorthands from an expression function body.
///
/// Function and method declarations already have an explicit return type and in
/// cases when that type is the same as the returned instance, the instance can be
/// simplified to a dot shorthand without reducing readability.
///
/// **BAD:**
/// ```dart
/// SomeClass getInstance() => SomeClass('val');
///
/// SomeClass getInstance() => SomeClass.named('val');
///
/// SomeClass getInstance(bool flag) =>
///     flag ? SomeClass('value') : SomeClass.named('val');
/// ```
///
/// **GOOD:**
/// ```dart
/// SomeClass getInstance() => .new('val');
///
/// SomeClass getInstance() => .named('val');
///
/// SomeClass getInstance(bool flag) =>
///     flag ? .new('value') : .named('val');
/// ```
class PreferReturningShorthands extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_returning_shorthands',
    'This instance type matches the return type and can be replaced with a dot shorthand.',
    correctionMessage: 'Try using the dot shorthand constructor.',
  );

  PreferReturningShorthands()
    : super(
        name: 'prefer_returning_shorthands',
        description:
            'Suggests returning dot shorthands from an expression function body.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
    registry.addConstructorDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferReturningShorthands rule;

  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _checkFunctionBody(node.functionExpression.body, node.returnType?.type);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _checkFunctionBody(node.body, node.returnType?.type);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    // For constructors, the return type is the containing class
    final classNode = node.parent?.parent;
    if (classNode is! ClassDeclaration) return;

    final classElement = classNode.declaredFragment?.element;
    if (classElement == null) return;

    _checkFunctionBody(node.body, classElement.thisType);
  }

  void _checkFunctionBody(FunctionBody body, DartType? returnType) {
    // Only check expression function bodies (arrow functions)
    if (body is! ExpressionFunctionBody) return;

    // Return type must be specified
    if (returnType == null) return;

    // Don't suggest shorthands for non-interface types (including dynamic)
    if (returnType is! InterfaceType) return;

    // Check the expression
    _checkExpression(body.expression, returnType);
  }

  void _checkExpression(Expression expression, InterfaceType returnType) {
    switch (expression) {
      case InstanceCreationExpression():
        _checkInstanceCreation(expression, returnType);
      case MethodInvocation():
        _checkMethodInvocation(expression, returnType);
      case ConditionalExpression():
        _checkExpression(expression.thenExpression, returnType);
        _checkExpression(expression.elseExpression, returnType);
      case ParenthesizedExpression():
        _checkExpression(expression.expression, returnType);
    }
  }

  void _checkInstanceCreation(
    InstanceCreationExpression node,
    InterfaceType returnType,
  ) {
    // Get the class element
    final typeName = node.constructorName.type;
    final typeElement = typeName.element;
    if (typeElement is! InterfaceElement) return;

    // Check if the instance type matches the return type (ignoring nullability)
    if (!_isTypeCompatible(returnType, typeElement)) return;

    // Report the lint
    rule.reportAtNode(node.constructorName);
  }

  void _checkMethodInvocation(MethodInvocation node, InterfaceType returnType) {
    // Check if this is a named constructor invocation (e.g., SomeClass.named)
    // These can appear as method invocations in the AST
    if (node.target is! SimpleIdentifier) return;

    final target = node.target as SimpleIdentifier;

    // Get the static type to verify it's actually a constructor call
    final staticType = node.staticType;
    if (staticType is! InterfaceType) return;

    final typeElement = staticType.element;

    // Verify the target name matches the class name
    if (target.name != typeElement.name) return;

    // Check if the instance type matches the return type
    if (!_isTypeCompatible(returnType, typeElement)) return;

    // Report the lint - we report at the target but the fix will handle
    // the entire "ClassName.constructorName" range
    rule.reportAtToken(target.token);
  }

  /// Checks if the context type is compatible with the constructor's class.
  bool _isTypeCompatible(
    InterfaceType returnType,
    InterfaceElement classElement,
  ) {
    // Check if the return type matches the class type (ignoring nullability)
    return returnType.element == classElement;
  }
}
