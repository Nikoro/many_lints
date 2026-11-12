import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class AvoidSelfCompare extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_self_compare',
    'This compares a value against itself, which is always 0.',
    correctionMessage:
        'Compare against the other value you meant, or remove the '
        'comparison.',
  );

  AvoidSelfCompare()
    : super(
        name: 'avoid_self_compare',
        description:
            'Warns when the receiver and the argument of compareTo are the '
            'same expression, so the result is always 0.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidSelfCompare rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'compareTo') return;

    final target = node.target;
    if (target == null) return;

    if (node.argumentList.arguments case [final Expression only]) {
      final receiver = _unwrapParentheses(target);
      final argument = _unwrapParentheses(only);

      if (!_isSideEffectFree(receiver) || !_isSideEffectFree(argument)) return;
      if (receiver.toSource() != argument.toSource()) return;

      rule.reportAtNode(node);
    }
  }

  bool _isSideEffectFree(Expression expression) => switch (expression) {
    ThisExpression() ||
    BooleanLiteral() ||
    IntegerLiteral() ||
    DoubleLiteral() ||
    SimpleStringLiteral() ||
    NullLiteral() => true,
    SimpleIdentifier(:final element) => _isStableRead(element),
    PrefixedIdentifier(:final prefix, :final identifier) =>
      _isSideEffectFree(prefix) && _isStableRead(identifier.element),
    PropertyAccess(:final target?, :final propertyName) =>
      _isSideEffectFree(target) && _isStableRead(propertyName.element),
    ParenthesizedExpression(:final expression) => _isSideEffectFree(expression),
    _ => false,
  };

  bool _isStableRead(Element? element) => switch (element) {
    LocalVariableElement() || FormalParameterElement() => true,
    FieldElement() => true,
    // Edge case: a hand-written getter body can return anything, only the synthetic one is stable
    GetterElement(:final variable) =>
      variable is FieldElement && !element.isOriginDeclaration,
    _ => false,
  };

  Expression _unwrapParentheses(Expression expression) => switch (expression) {
    ParenthesizedExpression(:final expression) => _unwrapParentheses(
      expression,
    ),
    _ => expression,
  };
}
