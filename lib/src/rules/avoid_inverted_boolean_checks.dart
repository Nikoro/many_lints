import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class AvoidInvertedBooleanChecks extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_inverted_boolean_checks',
    "This negated comparison can be written as '{0}'.",
    correctionMessage:
        'Use the opposite operator instead of negating the comparison.',
  );

  AvoidInvertedBooleanChecks()
    : super(
        name: 'avoid_inverted_boolean_checks',
        description:
            'Warns when a relational comparison is negated instead of using '
            'the opposite operator.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addPrefixExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidInvertedBooleanChecks rule;

  _Visitor(this.rule);

  // Edge case: == and != are left to avoid_unnecessary_negations, so the code is reported once
  static const _opposites = {'<': '>=', '<=': '>', '>': '<=', '>=': '<'};

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (node.operator.lexeme != '!') return;

    final operand = node.operand;
    if (operand is! ParenthesizedExpression) return;

    final inner = operand.expression;
    if (inner is! BinaryExpression) return;

    final opposite = _opposites[inner.operator.lexeme];
    if (opposite == null) return;

    // Edge case: NaN breaks the equivalence for doubles: !(nan > 1) is true while nan <= 1 is false
    if (!_isInt(inner.leftOperand) || !_isInt(inner.rightOperand)) return;

    final suggestion =
        '${inner.leftOperand.toSource()} $opposite '
        '${inner.rightOperand.toSource()}';
    rule.reportAtNode(node, arguments: [suggestion]);
  }

  bool _isInt(Expression expression) {
    final type = expression.staticType;
    if (type is! InterfaceType) return false;
    return type.element.name == 'int';
  }
}
