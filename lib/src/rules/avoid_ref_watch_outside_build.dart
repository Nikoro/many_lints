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

/// Warns when a subscribing provider read happens outside a `build()` method.
///
/// A subscribing read ties the current scope to a provider. Called from a
/// lifecycle method or an event handler it creates a subscription that is
/// never torn down properly, which leaks listeners and rebuilds at unexpected
/// times.
///
/// Covers both ecosystems, because the mistake is identical in each:
///
/// - **Riverpod** — `ref.watch(...)` outside `build`. Use `ref.read(...)` in
///   callbacks, or `ref.listen(...)` for side effects.
/// - **provider** — `context.watch<T>()` outside `build`. Use
///   `context.read<T>()`. This one is worse than Riverpod's: provider's
///   `watch` throws outright when called from `initState`, so the rule catches
///   a crash rather than a smell.
///
/// The two are told apart by the *receiver*, not the class: Riverpod's `ref`
/// exists only on a consumer, while provider's `context` is on every widget.
class AvoidRefWatchOutsideBuild extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_ref_watch_outside_build',
    "Avoid using '{0}.watch' outside the build method.",
    correctionMessage:
        "Use '{0}.read' for one-off reads in callbacks, or listen for changes "
        'instead of subscribing here.',
  );

  AvoidRefWatchOutsideBuild()
    : super(
        name: 'avoid_ref_watch_outside_build',
        description:
            'Warns when a subscribing provider read is used outside a build '
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
  final AvoidRefWatchOutsideBuild rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // `build` is exactly where `ref.watch` belongs.
    if (node.name.lexeme == 'build') return;

    final enclosingBody = node.parent;
    if (enclosingBody is! BlockClassBody) return;
    final classDecl = enclosingBody.parent;
    if (classDecl is! ClassDeclaration) return;

    final element = classDecl.declaredFragment?.element;
    if (element == null) return;

    // Riverpod's `ref` lives only on a consumer; provider's `context` lives on
    // every widget. So the class filter has to admit both, and the receiver
    // check in `_RefWatchFinder` is what actually tells the two apart.
    final isWidget =
        widgetChecker.isSuperOf(element) || stateChecker.isSuperOf(element);
    if (!consumerChecker.isSuperOf(element) && !isWidget) return;

    final finder = _RefWatchFinder(rule);
    node.body.visitChildren(finder);
  }
}

/// Recursively searches for `ref.watch(...)` calls.
///
/// Unlike the build-method rules, this one deliberately *does* descend into
/// closures: a `ref.watch` inside an `onPressed` callback is exactly the
/// leak this rule is meant to catch.
class _RefWatchFinder extends RecursiveAstVisitor<void> {
  final AvoidRefWatchOutsideBuild rule;

  _RefWatchFinder(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final receiver = receiverKind(node, 'watch');
    if (receiver != null) {
      rule.reportAtNode(node, arguments: [receiver]);
      return;
    }

    super.visitMethodInvocation(node);
  }
}
