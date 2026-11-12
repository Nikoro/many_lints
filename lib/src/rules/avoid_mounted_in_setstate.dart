import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../state_base_classes.dart';

class AvoidMountedInSetstate extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_mounted_in_setstate',
    'Checking mounted inside setState is too late and can lead to an exception.',
    correctionMessage: 'Check mounted before calling setState instead.',
  );

  AvoidMountedInSetstate()
    : super(
        name: 'avoid_mounted_in_setstate',
        description:
            'Warns when mounted is checked inside a setState callback.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidMountedInSetstate rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'setState') return;

    if (!_isInsideState(node)) return;

    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    final callback = args.first;
    if (callback is! FunctionExpression) return;

    callback.body.visitChildren(_MountedFinder(rule));
  }

  bool _isInsideState(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is ClassDeclaration) {
        final element = current.declaredFragment?.element;
        if (element != null && isStateElement(rule, element)) {
          return true;
        }
        return false;
      }
      current = current.parent;
    }
    return false;
  }
}

class _MountedFinder extends RecursiveAstVisitor<void> {
  final AvoidMountedInSetstate rule;

  _MountedFinder(this.rule);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == 'mounted' && !_isReportedByEnclosingAccess(node)) {
      rule.reportAtNode(node);
    }
    super.visitSimpleIdentifier(node);
  }

  bool _isReportedByEnclosingAccess(SimpleIdentifier node) =>
      switch (node.parent) {
        PrefixedIdentifier(:final identifier) => identifier == node,
        PropertyAccess(:final propertyName) => propertyName == node,
        _ => false,
      };

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == 'mounted') {
      rule.reportAtNode(node);
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == 'mounted') {
      rule.reportAtNode(node);
    }
    super.visitPropertyAccess(node);
  }
}
