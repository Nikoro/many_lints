import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class AvoidEqualExpressions extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_equal_expressions',
    "Both operands of '{0}' are identical.",
    correctionMessage:
        'This produces a constant result. Check whether one side was meant '
        'to be a different expression.',
  );

  AvoidEqualExpressions()
    : super(
        name: 'avoid_equal_expressions',
        description:
            'Warns when the left and right operands of a binary expression '
            'are the same, which is usually a typo.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addBinaryExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidEqualExpressions rule;

  _Visitor(this.rule);

  // Edge case: x + x and x * x are ordinary arithmetic, so + and * are left out
  static const _suspiciousOperators = {
    '==',
    '!=',
    '<',
    '<=',
    '>',
    '>=',
    '&&',
    '||',
    '-',
    '/',
    '~/',
    '%',
    '??',
  };

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final operator = node.operator.lexeme;
    if (!_suspiciousOperators.contains(operator)) return;

    final left = node.leftOperand;
    final right = node.rightOperand;

    if (!_isSideEffectFree(left) || !_isSideEffectFree(right)) return;

    if (left.toSource() != right.toSource()) return;

    // Edge case: x != x is the canonical NaN test for doubles
    if ((operator == '!=' || operator == '==') && _mayBeDouble(left)) return;

    rule.reportAtNode(node, arguments: [operator]);
  }

  bool _mayBeDouble(Expression expression) {
    final type = expression.staticType;
    // Edge case: an unresolved operand stays silent
    if (type == null) return true;
    final name = type.getDisplayString();
    return name == 'double' ||
        name == 'double?' ||
        name == 'num' ||
        name == 'num?';
  }

  bool _isSideEffectFree(Expression expression) => switch (expression) {
    SimpleIdentifier() => true,
    PrefixedIdentifier() => true,
    PropertyAccess(:final target) =>
      target == null || _isSideEffectFree(target),
    ThisExpression() => true,
    Literal() => true,
    ParenthesizedExpression(:final expression) => _isSideEffectFree(expression),
    IndexExpression(:final target, :final index) =>
      target != null && _isSideEffectFree(target) && _isSideEffectFree(index),
    _ => false,
  };
}
