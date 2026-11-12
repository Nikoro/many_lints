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
    if (node.name.lexeme == 'build') return;

    final enclosingBody = node.parent;
    if (enclosingBody is! BlockClassBody) return;
    final classDecl = enclosingBody.parent;
    if (classDecl is! ClassDeclaration) return;

    final element = classDecl.declaredFragment?.element;
    if (element == null) return;

    final isWidget =
        widgetChecker.isSuperOf(element) || stateChecker.isSuperOf(element);
    if (!consumerChecker.isSuperOf(element) && !isWidget) return;

    final finder = _RefWatchFinder(rule);
    node.body.visitChildren(finder);
  }
}

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
