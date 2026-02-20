import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../ast_node_analysis.dart';
import '../type_checker.dart';

/// Suggests using Align widget instead of Container with only alignment.
class PreferAlignOverContainer extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_align_over_container',
    'Use Align widget instead of the Container widget with only the alignment parameter',
    correctionMessage: 'Try using Align instead of Container.',
  );

  PreferAlignOverContainer()
    : super(
        name: 'prefer_align_over_container',
        description:
            'Use Align widget instead of Container when only alignment is set.',
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
  final PreferAlignOverContainer rule;

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
      parameter: 'alignment',
      ignoredParameters: {'key', 'child'},
    )) {
      rule.reportAtNode(node.constructorName);
    }
  }
}
