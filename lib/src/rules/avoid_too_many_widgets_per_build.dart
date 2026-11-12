import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../flutter_type_checkers.dart';
import '../many_lints_rule.dart';

class AvoidTooManyWidgetsPerBuild extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_too_many_widgets_per_build',
    'This build method creates {0} widgets, over the limit of {1}.',
    correctionMessage:
        'Extract a part of the tree into its own widget, so each has a name.',
  );

  AvoidTooManyWidgetsPerBuild()
    : super(
        name: 'avoid_too_many_widgets_per_build',
        description:
            'Warns when one build method creates more widgets than the '
            'configured budget.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodDeclaration(this, _Visitor(this));
  }
}

const _defaultMaxWidgets = 20;

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidTooManyWidgetsPerBuild rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!_returnsWidget(node)) return;

    final maxWidgets = rule.config.intOption(
      'max_widgets',
      defaultValue: _defaultMaxWidgets,
    );

    final counter = _WidgetCounterOutsideClosures();
    node.body.accept(counter);

    if (counter.count <= maxWidgets) return;

    rule.reportAtToken(
      node.name,
      arguments: ['${counter.count}', '$maxWidgets'],
    );
  }

  bool _returnsWidget(MethodDeclaration node) {
    final returnType = node.returnType?.type;
    return returnType != null && widgetChecker.isAssignableFromType(returnType);
  }
}

class _WidgetCounterOutsideClosures extends RecursiveAstVisitor<void> {
  int count = 0;

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.staticType;
    if (type != null && widgetChecker.isAssignableFromType(type)) count++;

    super.visitInstanceCreationExpression(node);
  }
}
