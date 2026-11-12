import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../type_inference.dart';

class PreferReturningShorthands extends ManyLintsRule {
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
  void registerManyLintsProcessors(
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
    final classNode = node.parent?.parent;
    if (classNode is! ClassDeclaration) return;

    final classElement = classNode.declaredFragment?.element;
    if (classElement == null) return;

    _checkFunctionBody(node.body, classElement.thisType);
  }

  void _checkFunctionBody(FunctionBody body, DartType? returnType) {
    if (body is! ExpressionFunctionBody) return;
    if (returnType is! InterfaceType) return;

    _checkExpression(body.expression, returnType);
  }

  void _checkExpression(Expression expression, InterfaceType returnType) {
    switch (expression) {
      case InstanceCreationExpression():
        _checkInstanceCreation(expression, returnType);
      // Edge case: `SomeClass.named(...)` can reach the AST as a method invocation.
      case MethodInvocation():
        _checkNamedConstructorInvocation(expression, returnType);
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
    final typeName = node.constructorName.type;
    final typeElement = typeName.element;
    if (typeElement is! InterfaceElement) return;
    if (!isTypeCompatible(returnType, typeElement)) return;

    rule.reportAtNode(node.constructorName);
  }

  void _checkNamedConstructorInvocation(
    MethodInvocation node,
    InterfaceType returnType,
  ) {
    final target = node.target;
    if (target is! SimpleIdentifier) return;

    final staticType = node.staticType;
    if (staticType is! InterfaceType) return;

    final typeElement = staticType.element;
    if (target.name != typeElement.name) return;
    if (!isTypeCompatible(returnType, typeElement)) return;

    rule.reportAtToken(target.token);
  }
}
