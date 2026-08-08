import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../hook_detection.dart';
import '../type_checker.dart';

/// Warns when a hook is called outside a hook context.
///
/// Hooks are positional: `flutter_hooks` matches each call to stored state
/// by its index in the call sequence. That only works inside a
/// `HookWidget.build`, a `HookBuilder`'s `builder`, or another hook
/// function. Calling a hook from an event handler, a lifecycle method, or a
/// plain helper either throws or corrupts the hook order.
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

  static const _hookWidgetChecker = TypeChecker.any([
    TypeChecker.fromName('HookWidget', packageName: 'flutter_hooks'),
    TypeChecker.fromName('HookConsumerWidget', packageName: 'hooks_riverpod'),
    TypeChecker.fromName('HookState', packageName: 'flutter_hooks'),
  ]);

  @override
  void visitMethodInvocation(MethodInvocation node) => _check(node);

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) =>
      _check(node);

  void _check(InvocationExpression node) {
    final name = node.beginToken.lexeme;
    if (!hookNameRegex.hasMatch(name)) return;

    // A qualified call like `controller.useSomething()` is not a hook.
    if (node case MethodInvocation(
      target: final target?,
    ) when target is! ThisExpression) {
      return;
    }

    if (!_isInHookContext(node)) {
      rule.reportAtNode(node, arguments: [name]);
    }
  }

  /// Walks outward from [node] to the first enclosing function-like scope
  /// and decides whether that scope is a valid hook context.
  bool _isInHookContext(AstNode node) {
    for (AstNode? current = node; current != null; current = current.parent) {
      // A hook function: `Foo useFoo() { ... }` or `void _useBar() { ... }`.
      if (current is FunctionDeclaration) {
        return hookNameRegex.hasMatch(current.name.lexeme);
      }

      if (current is MethodDeclaration) {
        // A hook method, or the build method of a hook widget.
        if (hookNameRegex.hasMatch(current.name.lexeme)) return true;
        if (current.name.lexeme != 'build') return false;
        return _isHookWidgetMember(current);
      }

      // A closure: valid only if it is a HookBuilder's `builder` argument.
      if (current is FunctionExpression) {
        final parent = current.parent;

        // The body of a named function/method is not a closure boundary —
        // keep walking so the declaration itself decides.
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

    // Top-level code with no enclosing function — not a hook context.
    return false;
  }

  bool _isHookWidgetMember(MethodDeclaration method) {
    final body = method.parent;
    if (body is! BlockClassBody) return false;
    final classDecl = body.parent;
    if (classDecl is! ClassDeclaration) return false;

    final element = classDecl.declaredFragment?.element;
    if (element == null) return false;
    return _hookWidgetChecker.isSuperOf(element);
  }
}
