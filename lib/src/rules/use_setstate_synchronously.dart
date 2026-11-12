import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../async_guard_utils.dart';
import '../many_lints_rule.dart';
import '../state_base_classes.dart';

class UseSetstateSynchronously extends ManyLintsRule {
  static const LintCode code = LintCode(
    'use_setstate_synchronously',
    "'setState' is called after an await without a 'mounted' guard.",
    correctionMessage:
        "Add 'if (!mounted) return;' after the await, so a disposed widget "
        'does not rebuild.',
  );

  UseSetstateSynchronously()
    : super(
        name: 'use_setstate_synchronously',
        description:
            'Warns when setState is called after an await point without a '
            'mounted guard.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final UseSetstateSynchronously rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) return;
    if (!isStateElement(rule, element)) return;

    node.body.accept(_SetStateAfterAwaitFinder(rule));
  }
}

class _SetStateAfterAwaitFinder extends RecursiveAstVisitor<void> {
  _SetStateAfterAwaitFinder(this.rule);

  final UseSetstateSynchronously rule;

  @override
  void visitBlock(Block node) {
    var afterAwait = false;

    for (final statement in node.statements) {
      if (afterAwait && isMountedGuardWithReturn(statement)) {
        afterAwait = false;
        continue;
      }

      // Edge case: the else branch of a mounted guard runs while unmounted, so it stays checked
      if (afterAwait && isPositiveMountedGuard(statement)) {
        final guard = statement as IfStatement;
        final elseStatement = guard.elseStatement;
        if (elseStatement != null) _reportSetStateIn(elseStatement);

        _reportGuardedBranch(guard.thenStatement);
        continue;
      }

      if (afterAwait) _reportSetStateIn(statement);

      // Edge case: a setState in the same statement as the await runs before the gap
      if (containsAwait(statement)) afterAwait = true;
    }

    super.visitBlock(node);
  }

  void _reportGuardedBranch(Statement branch) {
    if (branch is Block) return;
    if (containsAwait(branch)) _reportSetStateIn(branch);
  }

  void _reportSetStateIn(Statement statement) {
    final finder = _SetStateFinder();
    statement.accept(finder);

    for (final invocation in finder.invocations) {
      rule.reportAtNode(invocation.methodName);
    }
  }
}

class _SetStateFinder extends RecursiveAstVisitor<void> {
  final invocations = <MethodInvocation>[];

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isOwnSetState(node)) invocations.add(node);

    super.visitMethodInvocation(node);
  }

  bool _isOwnSetState(MethodInvocation node) =>
      node.methodName.name == 'setState' && node.target == null;
}
