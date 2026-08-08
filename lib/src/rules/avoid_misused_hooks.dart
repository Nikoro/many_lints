import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../hook_detection.dart';

/// Warns when a hook is called inside a loop.
///
/// `flutter_hooks` identifies stored state by the *position* of each hook
/// call in the build sequence. A hook inside a loop runs a data-dependent
/// number of times, so the positions shift whenever the iteration count
/// changes and hooks start reading each other's state.
///
/// This complements `avoid_conditional_hooks`, which covers the
/// if/switch/ternary half of the same rule.
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
    if (!hookNameRegex.hasMatch(node.beginToken.lexeme)) return;

    // A qualified call like `controller.useSomething()` is not a hook.
    if (node case MethodInvocation(
      target: final target?,
    ) when target is! ThisExpression) {
      return;
    }

    if (_isInsideLoop(node)) {
      rule.reportAtNode(node);
    }
  }

  /// Whether [node] sits inside a loop that is itself within the current
  /// function scope.
  ///
  /// The walk stops at the enclosing function so a hook inside a closure
  /// that merely *appears* below a loop is not blamed for it.
  bool _isInsideLoop(AstNode node) {
    for (AstNode? current = node; current != null; current = current.parent) {
      if (current is ForStatement ||
          current is WhileStatement ||
          current is DoStatement ||
          current is ForElement) {
        return true;
      }

      // Reached the enclosing function scope without finding a loop.
      if (current is FunctionExpression ||
          current is FunctionDeclaration ||
          current is MethodDeclaration) {
        return false;
      }
    }
    return false;
  }
}
