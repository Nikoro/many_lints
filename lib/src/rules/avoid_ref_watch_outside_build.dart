import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../riverpod_type_checkers.dart';

/// Warns when `ref.watch()` is called outside of a `build()` method.
///
/// `ref.watch` subscribes the current scope to a provider. Calling it from a
/// lifecycle method or an event handler creates a subscription that is never
/// torn down properly, which leaks listeners and can rebuild at unexpected
/// times. Use `ref.read()` in callbacks and `ref.listen()` for side effects.
class AvoidRefWatchOutsideBuild extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_ref_watch_outside_build',
    "Avoid using 'ref.watch' outside the build method.",
    correctionMessage:
        "Use 'ref.read' for one-off reads in callbacks, or 'ref.listen' to "
        'react to provider changes.',
  );

  AvoidRefWatchOutsideBuild()
    : super(
        name: 'avoid_ref_watch_outside_build',
        description:
            'Warns when ref.watch() is used outside the build method of a '
            'Riverpod consumer widget, state, or notifier.',
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

    if (!consumerChecker.isSuperOf(element)) return;

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
    if (node.methodName.name == 'watch') {
      if (node.target case SimpleIdentifier(name: 'ref')) {
        rule.reportAtNode(node);
        return;
      }
    }
    super.visitMethodInvocation(node);
  }
}
