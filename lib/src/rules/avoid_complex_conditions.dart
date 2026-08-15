import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a condition combines more operands than the configured budget.
///
/// `a && b && !c || d` forces the reader to hold four facts and two precedence
/// rules at once, and it is where an `&&` that should have been `||` hides
/// longest. Naming the parts (`final isEligible = a && b;`) turns the
/// condition into something that can be read at a glance and debugged one
/// piece at a time.
///
/// Only `&&` and `||` are counted, through `max_operands`, defaulting to 3.
class AvoidComplexConditions extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_complex_conditions',
    'This condition combines {0} operands, over the limit of {1}.',
    correctionMessage: 'Name part of it, so each piece can be read on its own.',
  );

  AvoidComplexConditions()
    : super(
        name: 'avoid_complex_conditions',
        description:
            'Warns when a boolean condition combines more operands than the '
            'configured budget.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addBinaryExpression(this, _Visitor(this));
  }
}

/// Three operands is one `&&` chain a reader can still hold.
const _defaultMaxOperands = 3;

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidComplexConditions rule;

  _Visitor(this.rule);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (!_isLogical(node)) return;

    // Report at the root of the chain only, so `a && b && c` counts once.
    if (_hasLogicalParent(node)) return;

    // A hand-written `operator ==` is one `&&` per field by construction, and
    // splitting it would scatter an equality check that reads as a unit.
    if (_isInsideEqualityOperator(node)) return;

    final maxOperands = rule.config.intOption(
      'max_operands',
      defaultValue: _defaultMaxOperands,
    );

    final operands = _countOperands(node);
    if (operands <= maxOperands) return;

    rule.reportAtNode(node, arguments: ['$operands', '$maxOperands']);
  }

  /// Whether this condition is the body of `operator ==`.
  bool _isInsideEqualityOperator(AstNode node) {
    final method = node.thisOrAncestorOfType<MethodDeclaration>();
    return method != null && method.name.lexeme == '==';
  }

  bool _isLogical(Expression expression) =>
      expression is BinaryExpression &&
      (expression.operator.lexeme == '&&' ||
          expression.operator.lexeme == '||');

  /// Whether this expression is itself an operand of a larger logical chain.
  bool _hasLogicalParent(BinaryExpression node) {
    AstNode? current = node.parent;

    // Parentheses do not break a chain: `(a && b) && c` is still one.
    while (current is ParenthesizedExpression) {
      current = current.parent;
    }

    return current is BinaryExpression && _isLogical(current);
  }

  /// How many leaf operands the chain combines.
  int _countOperands(Expression expression) {
    final unwrapped = switch (expression) {
      ParenthesizedExpression(:final expression) => expression,
      _ => expression,
    };

    if (!_isLogical(unwrapped)) return 1;

    final binary = unwrapped as BinaryExpression;
    return _countOperands(binary.leftOperand) +
        _countOperands(binary.rightOperand);
  }
}
