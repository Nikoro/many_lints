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

/// Warns on every use of the null-assertion (`!`) operator.
///
/// `!` is an unchecked assertion, not a check: it tells the compiler a value is
/// non-null and throws at runtime when that turns out to be wrong. The type
/// system stops helping at exactly the point the value is most likely to be
/// null, so a mistake surfaces as a `TypeError` in production rather than as an
/// analysis error.
///
/// This is deliberately stricter than the SDK's own `unnecessary_null_checks`
/// and `null_check_on_nullable_type_parameter`, which flag only *redundant* or
/// unsound bangs. This rule takes the position that a nullable value should be
/// narrowed — with `?.`, `??`, a null check, or pattern matching — rather than
/// asserted away.
///
/// Reading a known-present entry out of a `Map` is exempt: `map[key]!` is the
/// idiomatic spelling, because `Map`'s index operator is nullable by design
/// regardless of what the map contains.
///
/// **Bad:**
/// ```dart
/// user!.name;
/// config.timeout!.inSeconds;
/// fetch()!.close();
/// ```
///
/// **Good:**
/// ```dart
/// user?.name;
/// config.timeout?.inSeconds;
/// if (user != null) user.name;
///
/// // Exempt: Map's index operator returns null for a missing key.
/// translations['title']!.toUpperCase();
/// ```
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
    // `!` is the only postfix operator that is a null assertion; `++` and `--`
    // arrive here too.
    if (node.operator.type != TokenType.BANG) return;

    var operand = node.operand;
    while (operand is ParenthesizedExpression) {
      operand = operand.expression;
    }

    // `map[key]!` is idiomatic: `Map.operator []` is declared to return a
    // nullable value whatever the map holds, so there is no narrowing the user
    // could do instead. `isAssignableFromType` walks `allSupertypes`, so a
    // `HashMap` or any other `Map` subtype is exempt too.
    if (operand is IndexExpression && _isMapIndex(operand)) return;

    // `ignore_checked_fields: true` accepts a bang on a field that a preceding
    // `if (field != null)` already proved non-null. The default reports it:
    // promotion does not apply to fields, so the bang is genuinely the thing
    // making the code compile, and it can still throw if another isolate or a
    // getter mutates the field in between.
    final ignoreCheckedFields = rule.config.boolOption(
      'ignore_checked_fields',
      defaultValue: false,
    );
    if (ignoreCheckedFields && _isGuardedByNullCheck(node, operand)) return;

    rule.reportAtNode(node);
  }

  /// Whether [node] indexes a `Map`.
  static bool _isMapIndex(IndexExpression node) {
    final targetType = node.realTarget.staticType;
    return targetType != null && _mapChecker.isAssignableFromType(targetType);
  }

  /// Whether [operand] names a field that an enclosing `if (x != null)` guards.
  ///
  /// Only the *condition* of an enclosing `if` is inspected, and the bang must
  /// sit inside the branch that condition proves non-null — the `then` branch
  /// for `!=`, the `else` branch for `==`.
  static bool _isGuardedByNullCheck(AstNode node, Expression operand) {
    final target = _canonicalElement(operand);
    if (target == null) return false;

    AstNode? current = node.parent;
    var child = node;
    while (current != null) {
      // A closure may run long after the guard, so a guard outside it proves
      // nothing about the field at the time the closure body executes.
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

  /// The `==` / `!=` operator of a plain `x == null` comparison, else `null`.
  static String? _nullCheckOperator(Expression condition) {
    if (condition is! BinaryExpression) return null;
    final operator = condition.operator.lexeme;
    if (operator != '!=' && operator != '==') return null;
    return _nullCheckedOperand(condition) == null ? null : operator;
  }

  /// The non-`null` side of a null comparison, or `null` when [condition] is
  /// not one.
  static Expression? _nullCheckedOperand(Expression condition) {
    if (condition is! BinaryExpression) return null;
    return switch ((condition.leftOperand, condition.rightOperand)) {
      (final Expression e, NullLiteral()) => e,
      (NullLiteral(), final Expression e) => e,
      _ => null,
    };
  }

  /// The element [expression] refers to, canonicalized so a read and a write of
  /// the same storage compare equal.
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
