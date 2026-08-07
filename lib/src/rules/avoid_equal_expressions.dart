import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when both operands of a binary expression are identical.
///
/// `a == a`, `x && x` and `value - value` are almost always typos: one
/// operand was meant to be a different variable, field, or index. The
/// expression compiles and produces a constant result, so nothing fails
/// until the wrong branch is taken.
class AvoidEqualExpressions extends AnalysisRule {
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
  void registerNodeProcessors(
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

  /// Operators where identical operands signal a mistake.
  ///
  /// `+`, `*` and the bit shifts are excluded: `x + x` and `x * x` are
  /// ordinary arithmetic, not errors.
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

    // `x != x` is the canonical NaN test for doubles, and `x == x` its
    // inverse. Both are deliberate when the operand can be a double.
    if ((operator == '!=' || operator == '==') && _mayBeDouble(left)) return;

    rule.reportAtNode(node, arguments: [operator]);
  }

  /// Whether [expression] could hold a `double`, making a self-comparison a
  /// deliberate NaN check rather than a typo.
  bool _mayBeDouble(Expression expression) {
    final type = expression.staticType;
    if (type == null) return true; // Unresolved — stay silent.
    final name = type.getDisplayString();
    return name == 'double' ||
        name == 'double?' ||
        name == 'num' ||
        name == 'num?';
  }

  /// Whether an expression can be evaluated twice with the same result.
  ///
  /// A method call may return something different each time — `next() ==
  /// next()` is a legitimate comparison — so only plain reads are
  /// considered.
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
