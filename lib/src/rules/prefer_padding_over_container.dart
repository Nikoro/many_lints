import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../ast_node_analysis.dart';
import '../flutter_type_checkers.dart';

/// Suggests using Padding widget instead of Container with only padding or margin.
class PreferPaddingOverContainer extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_padding_over_container',
    'Use Padding widget instead of the Container widget with only the padding or margin parameter',
    correctionMessage: 'Try using Padding instead of Container.',
  );

  PreferPaddingOverContainer()
    : super(
        name: 'prefer_padding_over_container',
        description:
            'Use Padding widget instead of Container when only padding or margin is set.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferPaddingOverContainer rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!isExpressionExactlyType(node, containerChecker)) return;

    if (isInstanceCreationExpressionOnlyUsingParameter(
          node,
          parameter: 'margin',
          ignoredParameters: {'key', 'child'},
        ) ||
        isInstanceCreationExpressionOnlyUsingParameter(
          node,
          parameter: 'padding',
          ignoredParameters: {'key', 'child'},
        )) {
      rule.reportAtNode(node.constructorName);
    }
  }
}
