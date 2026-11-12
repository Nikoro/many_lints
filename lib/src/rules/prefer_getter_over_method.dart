import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class PreferGetterOverMethod extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_getter_over_method',
    "'{0}' takes no arguments and computes nothing; make it a getter.",
    correctionMessage: "Declare it as 'get {0}' and drop the parentheses.",
  );

  PreferGetterOverMethod()
    : super(
        name: 'prefer_getter_over_method',
        description:
            'Warns when a no-argument method only reads a value, where a '
            'getter reads as the property it is.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodDeclaration(this, _Visitor(this));
  }
}

const _methodsInvokedByConvention = <String>{
  'toJson',
  'toMap',
  'call',
  'copyWith',
  'toList',
  'toSet',
  'toString',
  'noSuchMethod',
};

class _Visitor extends SimpleAstVisitor<void> {
  final PreferGetterOverMethod rule;

  _Visitor(this.rule);

  bool _isMoreThanFieldReads(FunctionBody body) {
    final visitor = _InvocationFinder();
    body.accept(visitor);
    return visitor.found;
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.isGetter || node.isSetter || node.isOperator) return;

    if (_methodsInvokedByConvention.contains(node.name.lexeme)) return;

    final mustKeepSupertypeShape = node.metadata.any(
      (a) => a.name.name == 'override',
    );
    if (mustKeepSupertypeShape) return;

    final takesTypeArguments = node.typeParameters != null;
    if (takesTypeArguments) return;

    if (node.parameters?.parameters.isNotEmpty ?? true) return;

    final returnType = node.returnType;
    final isCalledForEffect =
        returnType is NamedType && returnType.name.lexeme == 'void';
    if (isCalledForEffect) return;
    if (returnType == null) return;

    if (node.body is! ExpressionFunctionBody) return;

    if (node.body.isAsynchronous || node.body.isGenerator) return;

    final returnsSubscribableOrAwaitable =
        returnType is NamedType &&
        const {'Stream', 'Future'}.contains(returnType.name.lexeme);
    if (returnsSubscribableOrAwaitable) return;

    if (_isMoreThanFieldReads(node.body)) return;

    rule.reportAtToken(node.name, arguments: [node.name.lexeme]);
  }
}

class _InvocationFinder extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    found = true;
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    found = true;
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    found = true;
  }
}
