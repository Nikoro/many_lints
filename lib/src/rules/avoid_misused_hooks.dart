import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../ast_node_analysis.dart';
import '../hook_detection.dart';
import '../many_lints_rule.dart';

class AvoidMisusedHooks extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_misused_hooks',
    'Hooks must be called the same number of times on every build.',
    correctionMessage:
        'Move this hook to the top level of the build body, outside the loop.',
  );

  AvoidMisusedHooks()
    : super(
        name: 'avoid_misused_hooks',
        description:
            'Warns when a hook is called inside a loop, which shifts hook '
            'positions between builds.',
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
    registry.addFunctionExpressionInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidMisusedHooks rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) => _check(node);

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) =>
      _check(node);

  void _check(InvocationExpression node) {
    final name = node.beginToken.lexeme;
    if (!isHookInvocation(node)) return;

    if (rule.config.stringListOption('ignored_names').contains(name)) return;

    final ignoredWidgets = rule.config.stringListOption('ignored_widgets');
    if (ignoredWidgets.isNotEmpty) {
      final widget = enclosingClassDeclaration(node)?.namePart.typeName.lexeme;
      if (widget != null && ignoredWidgets.contains(widget)) return;
    }

    if (_isQualifiedCall(node)) return;

    if (_isInsideLoop(node)) {
      rule.reportAtNode(node);
    }
  }

  bool _isQualifiedCall(InvocationExpression node) =>
      node is MethodInvocation &&
      node.target != null &&
      node.target is! ThisExpression;

  bool _isInsideLoop(AstNode node) {
    for (AstNode? current = node; current != null; current = current.parent) {
      if (current is ForStatement ||
          current is WhileStatement ||
          current is DoStatement ||
          current is ForElement) {
        return true;
      }

      if (current is FunctionExpression ||
          current is FunctionDeclaration ||
          current is MethodDeclaration) {
        return false;
      }
    }
    return false;
  }
}
