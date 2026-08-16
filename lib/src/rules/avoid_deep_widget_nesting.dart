import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../flutter_type_checkers.dart';
import '../many_lints_rule.dart';

/// Warns when a widget tree is nested more deeply than the configured budget.
///
/// Nesting depth is the metric that matches how a widget tree actually goes
/// wrong. A `build` can be short and still be unreadable: eight levels of
/// `Padding` inside `Column` inside `Expanded` push the widget that matters
/// off the right edge, and every edit has to count brackets to find its
/// place. Extracting a subtree into a named widget removes a whole level and
/// gives the part a name at the same time.
///
/// The limit is `max_depth`, defaulting to 8. Only widget instantiations are
/// counted, so the lists, closures and conditionals between them do not
/// inflate the number.
///
/// One diagnostic per tree: it is anchored at the root of the over-nested
/// tree — the widget whose subtree has to be split — and the number says how
/// far that subtree goes. Reporting each node that is itself too deep would
/// flag a ten-deep chain at every level past the budget, and would flag two
/// sibling leaves at the same depth twice for what is a single fix.
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

/// Deep enough that a tree reaching it is usually several widgets in one.
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

    // Only the root of a tree is examined, and it reports at most once. The
    // alternative — letting every node test its own depth — reports a ten-deep
    // chain at every level past the budget, and reports two sibling leaves at
    // the same depth twice for what is one fix. Both showed up on real code.
    if (_depthOf(node) != 1) return;

    final deepest = _descendantDepth(node) + 1;
    if (deepest <= maxDepth) return;

    // Anchored at the root rather than the leaf: that is the widget whose
    // subtree has to be split, and the number says how far it goes.
    rule.reportAtNode(node, arguments: ['$deepest', '$maxDepth']);
  }

  /// How many widget instantiations enclose [node], including itself.
  ///
  /// Counted by walking up rather than down, so the number is the depth of
  /// this widget in its tree regardless of how many siblings it has. The walk
  /// stops at a function body, because a widget built inside a `builder:`
  /// closure starts a tree of its own — its depth is not the caller's.
  int _depthOf(InstanceCreationExpression node) {
    var depth = 1;
    AstNode? current = node.parent;

    while (current != null) {
      if (current is FunctionBody) break;
      if (current is InstanceCreationExpression && _isWidget(current)) depth++;
      current = current.parent;
    }

    return depth;
  }

  /// How many further widget levels sit below [node], along its deepest path.
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

/// Measures the longest chain of nested widgets inside a subtree.
///
/// A `builder:` closure is skipped for the same reason the upward walk stops
/// at a function body: it builds a tree of its own, whose depth is not this
/// one's.
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
