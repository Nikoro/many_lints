import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

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

const _defaultMaxOperands = 3;

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidComplexConditions rule;

  _Visitor(this.rule);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (!_isLogical(node)) return;

    if (_hasLogicalParent(node)) return;

    // Edge case: operator == is one && per field by construction and reads as a unit
    if (_isInsideEqualityOperator(node)) return;

    final maxOperands = rule.config.intOption(
      'max_operands',
      defaultValue: _defaultMaxOperands,
    );

    final operands = _countOperands(node);
    if (operands <= maxOperands) return;

    rule.reportAtNode(node, arguments: ['$operands', '$maxOperands']);
  }

  bool _isInsideEqualityOperator(AstNode node) {
    final method = node.thisOrAncestorOfType<MethodDeclaration>();
    return method != null && method.name.lexeme == '==';
  }

  bool _isLogical(Expression expression) =>
      expression is BinaryExpression &&
      (expression.operator.lexeme == '&&' ||
          expression.operator.lexeme == '||');

  bool _hasLogicalParent(BinaryExpression node) {
    AstNode? current = node.parent;

    while (current is ParenthesizedExpression) {
      current = current.parent;
    }

    return current is BinaryExpression && _isLogical(current);
  }

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
