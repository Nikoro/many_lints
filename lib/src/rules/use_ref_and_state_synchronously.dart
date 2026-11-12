import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../async_guard_utils.dart';
import '../riverpod_type_checkers.dart';

class UseRefAndStateSynchronously extends ManyLintsRule {
  static const LintCode code = LintCode(
    'use_ref_and_state_synchronously',
    "Don't use 'ref' or 'state' after an async gap without checking "
        "'ref.mounted'.",
    correctionMessage:
        "Add 'if (!ref.mounted) return;' before accessing 'ref' or 'state' "
        'after an await.',
  );

  UseRefAndStateSynchronously()
    : super(
        name: 'use_ref_and_state_synchronously',
        description:
            'Warns when ref or state is accessed after an await point in '
            'a Riverpod Notifier without a mounted guard.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final UseRefAndStateSynchronously rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!node.body.isAsynchronous) return;

    final enclosingBody = node.parent;
    if (enclosingBody is! BlockClassBody) return;
    final classDecl = enclosingBody.parent;
    if (classDecl is! ClassDeclaration) return;

    final element = classDecl.declaredFragment?.element;
    if (element == null || !notifierChecker.isSuperOf(element)) return;

    final body = node.body;
    if (body is! BlockFunctionBody) return;

    _checkStatements(body.block.statements);
  }

  void _checkStatements(NodeList<Statement> statements) {
    var seenAwait = false;

    for (final statement in statements) {
      if (!seenAwait) {
        seenAwait = containsAwait(statement);
        continue;
      }

      if (isMountedGuardWithReturn(statement)) {
        seenAwait = false;
        continue;
      }

      final finder = _RefStateFinder(rule);
      statement.accept(finder);
    }
  }
}

class _RefStateFinder extends RecursiveAstVisitor<void> {
  final UseRefAndStateSynchronously rule;

  _RefStateFinder(this.rule);

  static const _targets = {'ref', 'state'};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target case SimpleIdentifier(
      name: final name,
    ) when _targets.contains(name)) {
      rule.reportAtNode(node);
      return;
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (_isMountedGuard(node.prefix.name, node.identifier.name)) return;

    if (_targets.contains(node.prefix.name)) {
      rule.reportAtNode(node);
      return;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!_targets.contains(node.name)) {
      super.visitSimpleIdentifier(node);
      return;
    }

    final parent = node.parent;
    if (parent is PrefixedIdentifier && parent.prefix == node) return;
    if (parent is PropertyAccess && parent.target == node) return;
    if (parent is MethodInvocation && parent.target == node) return;

    rule.reportAtNode(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (node.leftHandSide case SimpleIdentifier(name: 'state')) {
      rule.reportAtNode(node);
      return;
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.target case SimpleIdentifier(
      name: final name,
    ) when _targets.contains(name)) {
      if (_isMountedGuard(name, node.propertyName.name)) return;
      rule.reportAtNode(node);
      return;
    }
    super.visitPropertyAccess(node);
  }

  // Edge case: a closure may be stored and invoked later, outside this async gap
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}

  static bool _isMountedGuard(String target, String property) =>
      target == 'ref' && property == 'mounted';
}
