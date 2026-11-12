import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

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

    if (_enclosingConditional(node) != null) return;

    final depth = _depthOf(node);
    if (depth <= maxDepth) return;

    rule.reportAtNode(node, arguments: ['$depth', '$maxDepth']);
  }

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
