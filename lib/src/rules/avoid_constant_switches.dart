import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:many_lints/src/constant_expression.dart';

/// Warns when a switch statement or expression evaluates a constant expression.
///
/// A switch on a constant like `switch (SomeClass.constField)` or
/// `switch (42)` always takes the same branch, which usually indicates
/// a typo or a bug.
class AvoidConstantSwitches extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_constant_switches',
    'The switch expression is a constant, so the result is always the same.',
    correctionMessage:
        'Replace the switch expression with a variable or parameter.',
  );

  AvoidConstantSwitches()
    : super(
        name: 'avoid_constant_switches',
        description:
            'Warns when a switch statement or expression evaluates a constant '
            'expression.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addSwitchStatement(this, visitor);
    registry.addSwitchExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidConstantSwitches rule;

  _Visitor(this.rule);

  @override
  void visitSwitchStatement(SwitchStatement node) {
    if (isConstantExpression(node.expression)) {
      rule.reportAtNode(node.expression);
    }
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    if (isConstantExpression(node.expression)) {
      rule.reportAtNode(node.expression);
    }
  }
}
