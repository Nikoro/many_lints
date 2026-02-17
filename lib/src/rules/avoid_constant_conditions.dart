import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:many_lints/src/constant_expression.dart';

/// Warns when a binary comparison has constant operands on both sides.
///
/// A condition like `10 == 11` or `SomeClass.value == '1'` always evaluates
/// to the same result, which usually indicates a typo or a bug.
class AvoidConstantConditions extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_constant_conditions',
    'Both sides of this comparison are constants, so the result is always the '
        'same.',
    correctionMessage:
        'Replace one operand with a variable or remove the dead condition.',
  );

  AvoidConstantConditions()
    : super(
        name: 'avoid_constant_conditions',
        description:
            'Warns when a binary comparison has constant operands on both '
            'sides.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addBinaryExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidConstantConditions rule;

  _Visitor(this.rule);

  static const _comparisonOperators = {
    TokenType.EQ_EQ,
    TokenType.BANG_EQ,
    TokenType.LT,
    TokenType.GT,
    TokenType.LT_EQ,
    TokenType.GT_EQ,
  };

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (!_comparisonOperators.contains(node.operator.type)) return;

    if (!isConstantExpression(node.leftOperand) ||
        !isConstantExpression(node.rightOperand)) {
      return;
    }

    rule.reportAtNode(node);
  }
}
