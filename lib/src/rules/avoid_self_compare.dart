import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a value is passed to its own `compareTo`.
///
/// `a.compareTo(a)` is always `0`, so a sort or a comparison built on it
/// decides nothing. It is almost always a typo for a nearby variable — the
/// wrong name picked out of an autocomplete list, or a `compareTo` left
/// half-edited after a field was renamed.
///
/// The binary-operator form of this mistake (`a == a`, `a < a`) belongs to
/// [AvoidEqualExpressions], which reports it already; this rule deliberately
/// covers only the method call, so the two never report the same line.
///
/// Only receivers and arguments with no side effects are compared:
/// `next().compareTo(next())` reads the same but calls twice, so it is left
/// alone.
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

  /// Whether evaluating this expression twice is guaranteed to be equivalent
  /// to evaluating it once.
  ///
  /// Deliberately conservative: only literals, `this`, and reads of a local
  /// variable, parameter or field qualify. Anything that runs code may differ
  /// between the two evaluations, so the comparison could be doing real work —
  /// `it.current.compareTo(it.current)` is the motivating case, where
  /// `current` is a getter that reports a moving position.
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

  /// Whether reading this element twice yields the same value.
  ///
  /// A local variable, parameter or plain field is stable storage. A getter
  /// runs a method body, so it is only assumed stable when it is the implicit
  /// getter the compiler generates for a field.
  bool _isStableRead(Element? element) => switch (element) {
    LocalVariableElement() || FormalParameterElement() => true,
    FieldElement() => true,
    // A compiler-generated getter for a field has no declaration of its own;
    // one written by hand does, and its body can return anything.
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
