import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../ast_node_analysis.dart';
import '../hook_detection.dart';
import '../hook_type_checkers.dart';

class AvoidConditionalHooks extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_conditional_hooks',
    'Hooks should not be called conditionally.',
    correctionMessage:
        'Move the conditional logic inside the hook callback instead.',
  );

  AvoidConditionalHooks()
    : super(
        name: 'avoid_conditional_hooks',
        description: 'Warns when hooks are called inside conditional branches.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidConditionalHooks rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final superclass = node.extendsClause?.superclass;
    final superclassElement = superclass?.element;
    if (superclass == null || superclassElement == null) return;

    if (!hookWidgetChecker.isExactly(superclassElement)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    final buildMethod = body.members
        .whereType<MethodDeclaration>()
        .firstWhereOrNull((member) => member.name.lexeme == 'build');
    if (buildMethod == null) return;

    _checkBody(buildMethod.body);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final body = maybeHookBuilderBody(node);
    if (body == null) return;

    _checkBody(body);
  }

  void _checkBody(AstNode body) {
    final finder = _ConditionalHookFinder(rule);
    body.accept(finder);
  }
}

class _ConditionalHookFinder extends RecursiveAstVisitor<void> {
  final AvoidConditionalHooks rule;
  int _conditionalDepth = 0;

  _ConditionalHookFinder(this.rule);

  void _checkHookCall(AstNode node) {
    if (_conditionalDepth > 0 && isHookInvocation(node)) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _checkHookCall(node);
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _checkHookCall(node);
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // Edge case: a HookBuilder opens a hook context of its own, checked separately
    if (maybeHookBuilderBody(node) != null) return;
    _checkHookCall(node);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    node.expression.accept(this);

    _conditionalDepth++;
    node.thenStatement.accept(this);
    node.elseStatement?.accept(this);
    _conditionalDepth--;
  }

  @override
  void visitIfElement(IfElement node) {
    node.expression.accept(this);

    _conditionalDepth++;
    node.thenElement.accept(this);
    node.elseElement?.accept(this);
    _conditionalDepth--;
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    node.expression.accept(this);

    _conditionalDepth++;
    for (final member in node.members) {
      member.accept(this);
    }
    _conditionalDepth--;
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    node.expression.accept(this);

    _conditionalDepth++;
    for (final caseNode in node.cases) {
      caseNode.accept(this);
    }
    _conditionalDepth--;
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    node.condition.accept(this);

    _conditionalDepth++;
    node.thenExpression.accept(this);
    node.elseExpression.accept(this);
    _conditionalDepth--;
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final op = node.operator.lexeme;
    if (op == '&&' || op == '||') {
      node.leftOperand.accept(this);
      _conditionalDepth++;
      node.rightOperand.accept(this);
      _conditionalDepth--;
    } else {
      super.visitBinaryExpression(node);
    }
  }

  // Edge case: a closure is a separate invocation context, so its hooks are not conditional here
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}
