import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../riverpod_type_checkers.dart';

class AvoidRefInsideStateDispose extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_ref_inside_state_dispose',
    "Avoid accessing 'ref' inside the dispose() method.",
    correctionMessage:
        'Providers may already be disposed at this point. '
        'Remove the ref access or move it to an earlier lifecycle method.',
  );

  AvoidRefInsideStateDispose()
    : super(
        name: 'avoid_ref_inside_state_dispose',
        description:
            'Warns when ref is accessed inside the dispose() method '
            'of a ConsumerState class.',
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
  final AvoidRefInsideStateDispose rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'dispose') return;

    final enclosingBody = node.parent;
    if (enclosingBody is! BlockClassBody) return;
    final classDecl = enclosingBody.parent;
    if (classDecl is! ClassDeclaration) return;

    final element = classDecl.declaredFragment?.element;
    if (element == null || !consumerStateChecker.isSuperOf(element)) return;

    final finder = _RefUsageFinder(rule);
    node.body.visitChildren(finder);
  }
}

class _RefUsageFinder extends RecursiveAstVisitor<void> {
  final AvoidRefInsideStateDispose rule;

  _RefUsageFinder(this.rule);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name != 'ref') {
      super.visitSimpleIdentifier(node);
      return;
    }

    if (_isReportedByEnclosingAccess(node)) return;

    rule.reportAtNode(node);
    super.visitSimpleIdentifier(node);
  }

  bool _isReportedByEnclosingAccess(SimpleIdentifier node) =>
      switch (node.parent) {
        PrefixedIdentifier(:final prefix) => prefix == node,
        PropertyAccess(:final target) => target == node,
        MethodInvocation(:final target) => target == node,
        _ => false,
      };

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target case SimpleIdentifier(name: 'ref')) {
      rule.reportAtNode(node);
      return;
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.name == 'ref') {
      rule.reportAtNode(node);
      return;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.target case SimpleIdentifier(name: 'ref')) {
      rule.reportAtNode(node);
      return;
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}
