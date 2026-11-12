import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../type_checker.dart';

const _mapChecker = TypeChecker.fromUrl('dart:core#Map');

class AvoidNonNullAssertion extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_non_null_assertion',
    'Avoid using the null-assertion operator.',
    correctionMessage:
        "Use '?.', '??', a null check or pattern matching to handle the null "
        'case instead of asserting it away.',
  );

  AvoidNonNullAssertion()
    : super(
        name: 'avoid_non_null_assertion',
        description:
            'Warns when the null-assertion operator is used, since it throws '
            'at runtime instead of handling the null case.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addPostfixExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidNonNullAssertion rule;

  _Visitor(this.rule);

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (node.operator.type != TokenType.BANG) return;

    var operand = node.operand;
    while (operand is ParenthesizedExpression) {
      operand = operand.expression;
    }

    final ignoreMapIndexes = rule.config.boolOption(
      'ignore_map_indexes',
      defaultValue: true,
    );
    if (ignoreMapIndexes &&
        operand is IndexExpression &&
        _isMapIndex(operand)) {
      return;
    }

    final ignoreCheckedFields = rule.config.boolOption(
      'ignore_checked_fields',
      defaultValue: false,
    );
    if (ignoreCheckedFields && _isGuardedByNullCheck(node, operand)) return;

    rule.reportAtNode(node);
  }

  static bool _isMapIndex(IndexExpression node) {
    final targetType = node.realTarget.staticType;
    return targetType != null && _mapChecker.isAssignableFromType(targetType);
  }

  static bool _isGuardedByNullCheck(AstNode node, Expression operand) {
    final target = _canonicalElement(operand);
    if (target == null) return false;

    AstNode? current = node.parent;
    var child = node;
    while (current != null) {
      // Edge case: a closure may run long after the guard, when the field is null again
      if (current is FunctionExpression || current is FunctionBody) {
        return false;
      }

      if (current is IfStatement) {
        final guardedBranch = switch (_nullCheckOperator(current.expression)) {
          '!=' => current.thenStatement,
          '==' => current.elseStatement,
          _ => null,
        };
        if (guardedBranch != null &&
            identical(child, guardedBranch) &&
            _canonicalElement(_nullCheckedOperand(current.expression)) ==
                target) {
          return true;
        }
      }

      child = current;
      current = current.parent;
    }
    return false;
  }

  static String? _nullCheckOperator(Expression condition) {
    if (condition is! BinaryExpression) return null;
    final operator = condition.operator.lexeme;
    if (operator != '!=' && operator != '==') return null;
    return _nullCheckedOperand(condition) == null ? null : operator;
  }

  static Expression? _nullCheckedOperand(Expression condition) {
    if (condition is! BinaryExpression) return null;
    return switch ((condition.leftOperand, condition.rightOperand)) {
      (final Expression e, NullLiteral()) => e,
      (NullLiteral(), final Expression e) => e,
      _ => null,
    };
  }

  static Element? _canonicalElement(Expression? expression) {
    var target = expression;
    while (target is ParenthesizedExpression) {
      target = target.expression;
    }

    final element = switch (target) {
      SimpleIdentifier(:final element) => element,
      PrefixedIdentifier(:final identifier) => identifier.element,
      PropertyAccess(target: ThisExpression(), :final propertyName) =>
        propertyName.element,
      _ => null,
    };

    return switch (element) {
      GetterElement(:final variable) => variable,
      SetterElement(:final variable) => variable,
      _ => element,
    };
  }
}
