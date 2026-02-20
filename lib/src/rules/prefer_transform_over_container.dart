import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../ast_node_analysis.dart';
import '../type_checker.dart';

/// Suggests using Transform widget instead of Container with only transform.
class PreferTransformOverContainer extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_transform_over_container',
    'Use Transform widget instead of the Container widget with only the transform parameter',
    correctionMessage: 'Try using Transform instead of Container.',
  );

  PreferTransformOverContainer()
    : super(
        name: 'prefer_transform_over_container',
        description:
            'Use Transform widget instead of Container when only transform is set.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferTransformOverContainer rule;

  _Visitor(this.rule);

  static const _containerChecker = TypeChecker.fromName(
    'Container',
    packageName: 'flutter',
  );

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!isExpressionExactlyType(node, _containerChecker)) return;

    if (isInstanceCreationExpressionOnlyUsingParameter(
      node,
      parameter: 'transform',
      ignoredParameters: {'key', 'child'},
    )) {
      rule.reportAtNode(node.constructorName);
    }
  }
}
