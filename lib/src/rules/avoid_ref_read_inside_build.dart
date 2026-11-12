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

    final enclosingBody = node.parent;
    if (enclosingBody is! BlockClassBody) return;
    final classDecl = enclosingBody.parent;
    if (classDecl is! ClassDeclaration) return;

    final element = classDecl.declaredFragment?.element;
    if (element == null) return;

    final isConsumer =
        consumerWidgetChecker.isSuperOf(element) ||
        consumerStateChecker.isSuperOf(element);
    final isWidget =
        widgetChecker.isSuperOf(element) || stateChecker.isSuperOf(element);
    if (!isConsumer && !isWidget) return;

    final finder = _RefReadFinder(rule);
    node.body.visitChildren(finder);
  }
}

class _RefReadFinder extends RecursiveAstVisitor<void> {
  final AvoidRefReadInsideBuild rule;

  _RefReadFinder(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final receiver = receiverKind(node, 'read');
    if (receiver != null) {
      rule.reportAtNode(node, arguments: [receiver]);
      return;
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}
