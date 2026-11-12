import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../flutter_type_checkers.dart';
import '../many_lints_rule.dart';

class AvoidDeepWidgetNesting extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_deep_widget_nesting',
    'This widget is nested {0} levels deep, over the limit of {1}.',
    correctionMessage:
        'Extract a subtree into its own widget, which removes a level and '
        'names the part.',
  );

  AvoidDeepWidgetNesting()
    : super(
        name: 'avoid_deep_widget_nesting',
        description:
            'Warns when a widget tree is nested more deeply than the '
            'configured budget.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addInstanceCreationExpression(this, _Visitor(this));
  }
}

const _defaultMaxDepth = 8;

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidDeepWidgetNesting rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!_isWidget(node)) return;

    final maxDepth = rule.config.intOption(
      'max_depth',
      defaultValue: _defaultMaxDepth,
    );

    // Edge case: only the root reports, so a deep chain or two deep siblings report once
    if (_depthOf(node) != 1) return;

    final deepest = _descendantDepth(node) + 1;
    if (deepest <= maxDepth) return;

    rule.reportAtNode(node, arguments: ['$deepest', '$maxDepth']);
  }

  int _depthOf(InstanceCreationExpression node) {
    var depth = 1;
    AstNode? current = node.parent;

    while (current != null) {
      // Edge case: a widget built in a builder closure starts a tree of its own
      if (current is FunctionBody) break;
      if (current is InstanceCreationExpression && _isWidget(current)) depth++;
      current = current.parent;
    }

    return depth;
  }

  int _descendantDepth(InstanceCreationExpression node) {
    final finder = _DeepestWidgetFinder();
    node.argumentList.accept(finder);
    return finder.deepest;
  }

  bool _isWidget(InstanceCreationExpression node) {
    final type = node.staticType;
    return type != null && widgetChecker.isAssignableFromType(type);
  }
}

class _DeepestWidgetFinder extends RecursiveAstVisitor<void> {
  int deepest = 0;

  int _current = 0;

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.staticType;
    final isWidget = type != null && widgetChecker.isAssignableFromType(type);

    if (!isWidget) {
      super.visitInstanceCreationExpression(node);
      return;
    }

    _current++;
    if (_current > deepest) deepest = _current;
    super.visitInstanceCreationExpression(node);
    _current--;
  }
}
