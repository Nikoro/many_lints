import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:many_lints/src/type_checker.dart';
import 'package:many_lints/src/utils/helpers.dart';

/// Suggests using Padding widget instead of Container with only margin.
class PreferPaddingOverContainer extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_padding_over_container',
    'Use Padding widget instead of the Container widget with only the margin parameter',
  );

  PreferPaddingOverContainer()
      : super(
          name: 'prefer_padding_over_container',
          description: 'Use Padding widget instead of Container when only margin is set.',
        );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferPaddingOverContainer rule;

  _Visitor(this.rule);

  static const _containerChecker = TypeChecker.fromName('Container', packageName: 'flutter');

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!isExpressionExactlyType(node, _containerChecker)) return;

    if (isInstanceCreationExpressionOnlyUsingParameter(
      node,
      parameter: 'margin',
      ignoredParameters: {'key', 'child'},
    )) {
      rule.reportAtNode(node.constructorName);
    }
  }
}
