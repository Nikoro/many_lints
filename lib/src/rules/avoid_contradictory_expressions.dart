import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../constant_expression.dart';

/// Warns when a logical AND (`&&`) expression contains contradictory
/// comparisons on the same variable, resulting in a condition that always
/// evaluates to `false`.
///
/// For example, `x == 3 && x == 4` can never be true because `x` cannot
/// be both 3 and 4 at the same time.
class AvoidContradictoryExpressions extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_contradictory_expressions',
    'This condition contains contradictory comparisons and always evaluates '
        'to false.',
    correctionMessage:
        'Check the operands — one of the comparisons is likely a bug.',
  );

  AvoidContradictoryExpressions()
    : super(
        name: 'avoid_contradictory_expressions',
        description:
            'Warns when a logical AND expression contains contradictory '
            'comparisons that always evaluate to false.',
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
  final AvoidContradictoryExpressions rule;

  _Visitor(this.rule);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (node.operator.type != TokenType.AMPERSAND_AMPERSAND) return;

    // Only process the top-level && to avoid duplicate reports.
    if (node.parent case BinaryExpression(
      operator: Token(type: TokenType.AMPERSAND_AMPERSAND),
    )) {
      return;
    }

    // Flatten the && chain into individual comparison operands.
    final comparisons = <_Comparison>[];
    _collectComparisons(node, comparisons);

    if (comparisons.length < 2) return;

    // Check every pair for contradictions.
    for (var i = 0; i < comparisons.length; i++) {
      for (var j = i + 1; j < comparisons.length; j++) {
        if (_areContradictory(comparisons[i], comparisons[j])) {
          rule.reportAtNode(node);
          return;
        }
      }
    }
  }

  /// Recursively flatten `&&` chains into individual comparisons.
  static void _collectComparisons(Expression expr, List<_Comparison> out) {
    if (expr is BinaryExpression) {
      if (expr.operator.type == TokenType.AMPERSAND_AMPERSAND) {
        _collectComparisons(expr.leftOperand, out);
        _collectComparisons(expr.rightOperand, out);
        return;
      }

      final op = expr.operator.type;
      if (comparisonOperators.contains(op)) {
        out.add((left: expr.leftOperand, op: op, right: expr.rightOperand));
      }
    }
  }

  /// Two comparisons are contradictory if they cannot both be true.
  static bool _areContradictory(_Comparison a, _Comparison b) {
    // Case 1: Same operand pair, contradictory operators.
    // e.g., x == a && x != a, or x < a && x > a.
    if (_sameExpression(a.left, b.left) && _sameExpression(a.right, b.right)) {
      return _contradictsSameOperands(a.op, b.op);
    }
    if (_sameExpression(a.left, b.right) && _sameExpression(a.right, b.left)) {
      return _contradictsSameOperands(a.op, _flipOperator(b.op));
    }

    // Case 2: Both use == but share one operand and the other operands are
    // provably different literals. e.g., x == 3 && x == 4.
    if (a.op == TokenType.EQ_EQ && b.op == TokenType.EQ_EQ) {
      if (_hasDifferentLiteralValues(a, b)) return true;
    }

    return false;
  }

  /// Whether two operators on the **same** operand pair cannot both be true.
  static bool _contradictsSameOperands(TokenType op1, TokenType op2) {
    final pair = (op1, op2);
    return _contradictoryPairs.contains(pair) ||
        _contradictoryPairs.contains((op2, op1));
  }

  static const _contradictoryPairs = <(TokenType, TokenType)>{
    // x == a && x != a
    (TokenType.EQ_EQ, TokenType.BANG_EQ),
    // x == a && x < a
    (TokenType.EQ_EQ, TokenType.LT),
    // x == a && x > a
    (TokenType.EQ_EQ, TokenType.GT),
    // x < a && x > a
    (TokenType.LT, TokenType.GT),
  };

  /// Returns `true` when both comparisons use `==`, share one operand
  /// (the variable), and the other operands are provably different literals.
  /// e.g., `x == 3 && x == 4`.
  static bool _hasDifferentLiteralValues(_Comparison a, _Comparison b) {
    // Try all four orientations of the shared operand.
    if (_sameExpression(a.left, b.left) &&
        _areDifferentLiterals(a.right, b.right)) {
      return true;
    }
    if (_sameExpression(a.right, b.right) &&
        _areDifferentLiterals(a.left, b.left)) {
      return true;
    }
    if (_sameExpression(a.left, b.right) &&
        _areDifferentLiterals(a.right, b.left)) {
      return true;
    }
    if (_sameExpression(a.right, b.left) &&
        _areDifferentLiterals(a.left, b.right)) {
      return true;
    }
    return false;
  }

  /// Returns `true` when both expressions are literals with different values.
  static bool _areDifferentLiterals(Expression a, Expression b) {
    var exprA = a;
    var exprB = b;
    while (exprA is ParenthesizedExpression) {
      exprA = exprA.expression;
    }
    while (exprB is ParenthesizedExpression) {
      exprB = exprB.expression;
    }

    if (exprA is IntegerLiteral && exprB is IntegerLiteral) {
      return exprA.value != exprB.value;
    }
    if (exprA is DoubleLiteral && exprB is DoubleLiteral) {
      return exprA.value != exprB.value;
    }
    if (exprA is SimpleStringLiteral && exprB is SimpleStringLiteral) {
      return exprA.value != exprB.value;
    }
    if (exprA is BooleanLiteral && exprB is BooleanLiteral) {
      return exprA.value != exprB.value;
    }
    // NullLiteral vs NullLiteral — same value, not different.
    // Different literal types (e.g., int vs string) — can't meaningfully
    // compare, skip.
    return false;
  }

  /// Flip a comparison operator as if the operands were swapped.
  /// `a < b` becomes `b > a`, etc.
  static TokenType _flipOperator(TokenType op) {
    return switch (op) {
      TokenType.LT => TokenType.GT,
      TokenType.GT => TokenType.LT,
      TokenType.LT_EQ => TokenType.GT_EQ,
      TokenType.GT_EQ => TokenType.LT_EQ,
      _ => op, // ==, != are symmetric
    };
  }

  /// Check if two expressions refer to the same variable / identifier.
  static bool _sameExpression(Expression a, Expression b) {
    // Unwrap parentheses.
    var exprA = a;
    var exprB = b;
    while (exprA is ParenthesizedExpression) {
      exprA = exprA.expression;
    }
    while (exprB is ParenthesizedExpression) {
      exprB = exprB.expression;
    }

    // Two simple identifiers with the same element.
    if (exprA is SimpleIdentifier && exprB is SimpleIdentifier) {
      return exprA.element != null && exprA.element == exprB.element;
    }

    // Two prefixed identifiers: prefix.id (e.g. SomeClass.field).
    if (exprA is PrefixedIdentifier && exprB is PrefixedIdentifier) {
      return exprA.identifier.element != null &&
          exprA.identifier.element == exprB.identifier.element;
    }

    // Two property accesses: target.property.
    if (exprA is PropertyAccess && exprB is PropertyAccess) {
      return exprA.propertyName.element != null &&
          exprA.propertyName.element == exprB.propertyName.element &&
          _sameExpression(exprA.target!, exprB.target!);
    }

    // Literals with the same value.
    if (exprA is IntegerLiteral && exprB is IntegerLiteral) {
      return exprA.value == exprB.value;
    }
    if (exprA is DoubleLiteral && exprB is DoubleLiteral) {
      return exprA.value == exprB.value;
    }
    if (exprA is SimpleStringLiteral && exprB is SimpleStringLiteral) {
      return exprA.value == exprB.value;
    }
    if (exprA is BooleanLiteral && exprB is BooleanLiteral) {
      return exprA.value == exprB.value;
    }
    if (exprA is NullLiteral && exprB is NullLiteral) {
      return true;
    }

    // Prefix expressions (e.g., -1 == -1).
    if (exprA is PrefixExpression && exprB is PrefixExpression) {
      return exprA.operator.type == exprB.operator.type &&
          _sameExpression(exprA.operand, exprB.operand);
    }

    return false;
  }
}

typedef _Comparison = ({Expression left, TokenType op, Expression right});
