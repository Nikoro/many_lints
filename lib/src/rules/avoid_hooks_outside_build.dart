import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../hook_detection.dart';
import '../hook_type_checkers.dart';
import '../many_lints_rule.dart';

class AvoidHooksOutsideBuild extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_hooks_outside_build',
    "The hook '{0}' is called outside a hook context.",
    correctionMessage:
        'Call hooks directly in a HookWidget build method, a HookBuilder '
        "builder, or another hook function whose name starts with 'use'.",
  );

  AvoidHooksOutsideBuild()
    : super(
        name: 'avoid_hooks_outside_build',
        description:
            'Warns when a hook is called outside a HookWidget build method, '
            'a HookBuilder builder, or another hook function.',
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
  final AvoidHooksOutsideBuild rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) => _check(node);

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) =>
      _check(node);

  void _check(InvocationExpression node) {
    final name = node.beginToken.lexeme;
    if (!isHookInvocation(node)) return;

    // Edge case: controller.useSomething() is an ordinary method, not a hook
    if (node case MethodInvocation(
      target: final target?,
    ) when target is! ThisExpression) {
      return;
    }

    if (!_isInHookContext(node)) {
      rule.reportAtNode(node, arguments: [name]);
    }
  }

  bool _isInHookContext(AstNode node) {
    for (AstNode? current = node; current != null; current = current.parent) {
      if (current is FunctionDeclaration) {
        return hookNameRegex.hasMatch(current.name.lexeme);
      }

      if (current is MethodDeclaration) {
        if (hookNameRegex.hasMatch(current.name.lexeme)) return true;
        if (current.name.lexeme != 'build' &&
            !rule.config
                .stringListOption('additional_methods')
                .contains(current.name.lexeme)) {
          return false;
        }
        return _isHookWidgetMember(current);
      }

      if (current is FunctionExpression) {
        final parent = current.parent;

        // Edge case: the body of a named function is no closure; its declaration decides
        if (parent is FunctionDeclaration || parent is MethodDeclaration) {
          continue;
        }

        if (parent is NamedArgument && parent.name.lexeme == 'builder') {
          final creation = parent
              .thisOrAncestorOfType<InstanceCreationExpression>();
          if (creation != null && maybeHookBuilderBody(creation) != null) {
            return true;
          }
        }
        return false;
      }
    }

    return false;
  }

  bool _isHookWidgetMember(MethodDeclaration method) {
    final body = method.parent;
    if (body is! BlockClassBody) return false;
    final classDecl = body.parent;
    if (classDecl is! ClassDeclaration) return false;

    final element = classDecl.declaredFragment?.element;
    if (element == null) return false;
    return hookScopeChecker.isSuperOf(element);
  }
}
