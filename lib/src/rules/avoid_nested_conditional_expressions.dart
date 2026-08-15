import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a conditional expression is nested inside another one.
///
/// `a ? b : (c ? d : e)` packs a decision tree onto one line, and the reader
/// has to track which `?` each `:` belongs to. A `switch` expression or an
/// early return says the same thing with the branches lined up.
///
/// The depth is configurable through `max_depth`, defaulting to `1` — one
/// conditional, no nesting.
class AvoidNestedConditionalExpressions extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_nested_conditional_expressions',
    'This conditional is nested {0} deep, over the limit of {1}.',
    correctionMessage:
        'Use a switch expression, or pull a branch into its own name.',
  );

  AvoidNestedConditionalExpressions()
    : super(
        name: 'avoid_nested_conditional_expressions',
        description:
            'Warns when conditional expressions are nested more deeply than '
            'the configured limit.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addConditionalExpression(this, _Visitor(this));
  }
}

/// One conditional, no nesting.
const _defaultMaxDepth = 1;

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidNestedConditionalExpressions rule;

  _Visitor(this.rule);

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    final maxDepth = rule.config.intOption(
      'max_depth',
      defaultValue: _defaultMaxDepth,
    );

    // Report at the outermost conditional only, so one nested chain produces
    // one diagnostic rather than one per level.
    if (_enclosingConditional(node) != null) return;

    final depth = _depthOf(node);
    if (depth <= maxDepth) return;

    rule.reportAtNode(node, arguments: ['$depth', '$maxDepth']);
  }

  /// The nearest conditional this one sits inside, ignoring parentheses.
  ConditionalExpression? _enclosingConditional(ConditionalExpression node) {
    for (
      AstNode? current = node.parent;
      current != null;
      current = current.parent
    ) {
      if (current is ConditionalExpression) return current;
      if (current is! ParenthesizedExpression) return null;
    }
    return null;
  }

  /// How many conditionals deep this expression goes.
  int _depthOf(Expression expression) {
    final unwrapped = switch (expression) {
      ParenthesizedExpression(:final expression) => expression,
      _ => expression,
    };

    if (unwrapped is! ConditionalExpression) return 0;

    return 1 +
        [
          _depthOf(unwrapped.thenExpression),
          _depthOf(unwrapped.elseExpression),
        ].reduce((a, b) => a > b ? a : b);
  }
}
