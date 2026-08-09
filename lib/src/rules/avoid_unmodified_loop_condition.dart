import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when nothing in a `while` loop's body can change its condition.
///
/// If no variable the condition reads is ever assigned inside the loop, the
/// condition evaluates the same way forever: the loop either never runs or
/// never stops. Both are bugs — usually a forgotten increment, or the wrong
/// variable being advanced.
///
/// **Bad:**
/// ```dart
/// var i = 0;
/// while (i < items.length) {
///   print(items[i]); // `i` is never advanced — infinite loop
/// }
/// ```
///
/// **Good:**
/// ```dart
/// var i = 0;
/// while (i < items.length) {
///   print(items[i]);
///   i++;
/// }
/// ```
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
    // `while (true)` with a `break` is the idiomatic infinite loop, not a bug.
    if (condition is BooleanLiteral) return;

    final reads = _ConditionReadCollector();
    condition.accept(reads);

    // A condition that consults something other than plain variables — a
    // method call, a property, an `await` — may observe outside change on each
    // iteration, so nothing can be concluded from assignments alone.
    if (reads.hasOpaqueRead) return;
    if (reads.found.isEmpty) return;

    final mutations = _MutationCollector();
    body.accept(mutations);

    // Any jump out of the loop makes non-termination escapable, and a jump
    // that depends on runtime state is beyond this rule's reach.
    if (mutations.hasEscape) return;

    for (final element in reads.found) {
      if (mutations.assigned.contains(element)) return;
    }

    rule.reportAtNode(condition);
  }
}

/// Collects the variables a loop condition reads.
///
/// [hasOpaqueRead] records that the condition also consults something whose
/// value this rule cannot track, in which case its conclusion is unsafe.
class _ConditionReadCollector extends RecursiveAstVisitor<void> {
  final Set<Element> found = {};
  bool hasOpaqueRead = false;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final element = node.element;

    // Locals and parameters are the only storage whose every mutation is
    // visible in the loop body. A field can be changed by any method the body
    // calls, so treating it as unmodified would be a false positive.
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

/// Collects variables assigned in a loop body, and whether the body can exit
/// by other means.
class _MutationCollector extends RecursiveAstVisitor<void> {
  final Set<Element> assigned = {};
  bool hasEscape = false;

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
  void visitBreakStatement(BreakStatement node) => hasEscape = true;

  @override
  void visitReturnStatement(ReturnStatement node) => hasEscape = true;

  @override
  void visitThrowExpression(ThrowExpression node) => hasEscape = true;

  /// A closure may be invoked later and mutate anything it captures, so its
  /// mere presence makes the analysis unsafe.
  @override
  void visitFunctionExpression(FunctionExpression node) => hasEscape = true;
}
