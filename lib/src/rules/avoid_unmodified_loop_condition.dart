import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class AvoidUnmodifiedLoopCondition extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_unmodified_loop_condition',
    'Nothing in the loop body can change this condition.',
    correctionMessage:
        'Update a variable the condition reads, or use a different loop '
        'construct.',
  );

  AvoidUnmodifiedLoopCondition()
    : super(
        name: 'avoid_unmodified_loop_condition',
        description:
            'Warns when a while loop condition reads no variable that the '
            'body modifies, so the loop can never terminate or never runs.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addWhileStatement(this, visitor);
    registry.addDoStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnmodifiedLoopCondition rule;

  _Visitor(this.rule);

  @override
  void visitWhileStatement(WhileStatement node) =>
      _check(node.condition, node.body);

  @override
  void visitDoStatement(DoStatement node) => _check(node.condition, node.body);

  void _check(Expression condition, Statement body) {
    if (condition is BooleanLiteral) return;

    final reads = _ConditionReadCollector();
    condition.accept(reads);

    if (reads.hasOpaqueRead) return;
    if (reads.found.isEmpty) return;

    final mutations = _MutationCollector();
    body.accept(mutations);

    if (mutations.hasExitOrClosure) return;

    for (final element in reads.found) {
      if (mutations.assigned.contains(element)) return;
    }

    rule.reportAtNode(condition);
  }
}

class _ConditionReadCollector extends RecursiveAstVisitor<void> {
  final Set<Element> found = {};
  bool hasOpaqueRead = false;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final element = node.element;

    // Edge case: a field can change in any method the body calls, so only locals are tracked
    if (element is LocalVariableElement || element is FormalParameterElement) {
      found.add(element!);

      return;
    }

    if (element is GetterElement || element is FieldElement) {
      hasOpaqueRead = true;
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    hasOpaqueRead = true;
    super.visitMethodInvocation(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    hasOpaqueRead = true;
    super.visitPropertyAccess(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    hasOpaqueRead = true;
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    hasOpaqueRead = true;
    super.visitAwaitExpression(node);
  }
}

class _MutationCollector extends RecursiveAstVisitor<void> {
  final Set<Element> assigned = {};
  bool hasExitOrClosure = false;

  void _recordTarget(Expression target, {Element? writeElement}) {
    final element = switch (target) {
      SimpleIdentifier() => writeElement ?? target.element,
      _ => null,
    };
    if (element != null) assigned.add(_canonical(element));
  }

  static Element _canonical(Element element) => switch (element) {
    GetterElement(:final variable) => variable,
    SetterElement(:final variable) => variable,
    _ => element,
  };

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _recordTarget(node.leftHandSide, writeElement: node.writeElement);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _recordTarget(node.operand, writeElement: node.writeElement);
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _recordTarget(node.operand, writeElement: node.writeElement);
    super.visitPrefixExpression(node);
  }

  @override
  void visitBreakStatement(BreakStatement node) => hasExitOrClosure = true;

  @override
  void visitReturnStatement(ReturnStatement node) => hasExitOrClosure = true;

  @override
  void visitThrowExpression(ThrowExpression node) => hasExitOrClosure = true;

  @override
  void visitFunctionExpression(FunctionExpression node) =>
      hasExitOrClosure = true;
}
