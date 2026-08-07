import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a comparison is negated instead of being inverted.
///
/// `!(a > b)` is `a <= b` written the long way. Every relational operator
/// has a direct opposite, so the negation adds a step for the reader
/// without adding meaning.
class AvoidInvertedBooleanChecks extends AnalysisRule {
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
  void registerNodeProcessors(
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

  /// Relational operators and their exact opposites.
  ///
  /// `==`/`!=` are handled by `avoid_unnecessary_negations`, so they are
  /// left out here to avoid reporting the same code twice.
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

    // Restricted to `int` on purpose. For a user-defined type the operators
    // need not be consistent, and with doubles NaN breaks the equivalence:
    // `!(nan > 1)` is true while `nan <= 1` is false.
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
