import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:many_lints/src/ast_node_analysis.dart';
import 'package:many_lints/src/type_checker.dart';

/// Suggests using ConstrainedBox widget instead of Container with only constraints.
class PreferConstrainedBoxOverContainer extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_constrained_box_over_container',
    'Use ConstrainedBox widget instead of the Container widget with only the constraints parameter.',
    correctionMessage: 'Replace with ConstrainedBox.',
  );

  PreferConstrainedBoxOverContainer()
    : super(
        name: 'prefer_constrained_box_over_container',
        description:
            'Use ConstrainedBox widget instead of Container when only constraints is set.',
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
  final PreferConstrainedBoxOverContainer rule;

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
      parameter: 'constraints',
      ignoredParameters: {'key', 'child'},
    )) {
      rule.reportAtNode(node.constructorName);
    }
  }
}
