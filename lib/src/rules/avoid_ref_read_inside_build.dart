import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../flutter_type_checkers.dart';
import '../many_lints_rule.dart';
import '../provider_receiver.dart';
import '../riverpod_type_checkers.dart';
import '../state_base_classes.dart';

/// Warns when a one-off provider read happens inside a `build()` method.
///
/// A one-off read returns the value now and does not subscribe, so a `build`
/// that uses one renders from a value it will never be told has changed. The
/// widget then goes stale until something unrelated rebuilds it — a bug that
/// reproduces only in the order the user happened to tap things.
///
/// Covers both ecosystems, because the mistake is identical in each:
///
/// - **Riverpod** — `ref.read(...)` in the `build` of a `ConsumerWidget` or
///   `ConsumerState`. Use `ref.watch(...)`.
/// - **provider** — `context.read<T>()` in any widget's `build`. Use
///   `context.watch<T>()`.
///
/// The two are told apart by the *receiver*, not the class: Riverpod's `ref`
/// exists only on a consumer, while provider's `context` is on every widget.
class AvoidRefReadInsideBuild extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_ref_read_inside_build',
    "Avoid using '{0}.read' inside the build method.",
    correctionMessage:
        "Use '{0}.watch' instead so the widget rebuilds when the "
        "provider's value changes.",
  );

  AvoidRefReadInsideBuild()
    : super(
        name: 'avoid_ref_read_inside_build',
        description:
            'Warns when a one-off provider read is used inside a build '
            'method.',
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
  final AvoidRefReadInsideBuild rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'build') return;

    // Navigate to the enclosing class
    final enclosingBody = node.parent;
    if (enclosingBody is! BlockClassBody) return;
    final classDecl = enclosingBody.parent;
    if (classDecl is! ClassDeclaration) return;

    final element = classDecl.declaredFragment?.element;
    if (element == null) return;

    // Riverpod's `ref` lives only on a consumer; provider's `context` lives on
    // every widget. So the class filter has to admit both, and the receiver
    // check in `_RefReadFinder` is what actually tells the two apart — a
    // widget with no provider usage simply yields nothing.
    final isConsumer =
        consumerWidgetChecker.isSuperOf(element) ||
        consumerStateChecker.isSuperOf(element);
    final isWidget =
        widgetChecker.isSuperOf(element) || stateChecker.isSuperOf(element);
    if (!isConsumer && !isWidget) return;

    // Search for the one-off reads inside the build body (excluding closures)
    final finder = _RefReadFinder(rule);
    node.body.visitChildren(finder);
  }
}

/// Recursively searches for `ref.read(...)` calls inside a build body.
///
/// Stops at function boundaries (closures/lambdas) because `ref.read()`
/// inside event handlers like `onPressed: () => ref.read(...)` is intentional.
class _RefReadFinder extends RecursiveAstVisitor<void> {
  final AvoidRefReadInsideBuild rule;

  _RefReadFinder(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final receiver = receiverKind(node, 'read');
    if (receiver != null) {
      rule.reportAtNode(node, arguments: [receiver]);
      return; // Don't recurse — already reported
    }

    super.visitMethodInvocation(node);
  }

  // Stop at function boundaries — closures are intentional (e.g., onPressed)
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}
