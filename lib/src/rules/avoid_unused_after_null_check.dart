import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a variable is null-checked and then not used in the branch the
/// check guards.
///
/// `if (user != null) { ... }` exists to make `user` safely usable. When the
/// guarded branch never mentions it, the check is either dead weight or — far
/// more often — the branch uses the *wrong* variable, which is a real bug the
/// type system cannot see.
///
/// **Bad:**
/// ```dart
/// if (user != null) {
///   print(fallbackUser.name); // `user` was checked but never used
/// }
/// ```
///
/// **Good:**
/// ```dart
/// if (user != null) {
///   print(user.name);
/// }
/// ```
class AvoidUnusedAfterNullCheck extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_unused_after_null_check',
    "'{0}' is null-checked but not used in the guarded branch.",
    correctionMessage:
        'Use the checked variable in the branch, or remove the check if it '
        'guards nothing.',
  );

  AvoidUnusedAfterNullCheck()
    : super(
        name: 'avoid_unused_after_null_check',
        description:
            'Warns when a variable is null-checked but never used inside the '
            'branch that check guards.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addIfStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnusedAfterNullCheck rule;

  _Visitor(this.rule);

  @override
  void visitIfStatement(IfStatement node) {
    // An `else if` chain is visited through its own node.
    final checked = _nullCheckedVariable(node.expression);
    if (checked == null) return;

    final (element, name) = checked;

    // The guarded branch is the `then` for `x != null`, and the `else` for
    // `x == null` — where the early return leaves the rest usable.
    final guarded = switch (node.expression) {
      BinaryExpression(operator: final op) when op.lexeme == '!=' =>
        node.thenStatement,
      _ => node.elseStatement,
    };
    if (guarded == null) return;

    final usage = _UsageFinder(element);
    guarded.accept(usage);
    if (usage.found) return;

    rule.reportAtNode(node.expression, arguments: [name]);
  }

  /// The local variable or parameter compared against `null`, with the name to
  /// report, or `null` when the condition is not a plain null check.
  (Element, String)? _nullCheckedVariable(Expression condition) {
    if (condition is! BinaryExpression) return null;

    final operator = condition.operator.lexeme;
    if (operator != '!=' && operator != '==') return null;

    final (identifier, other) = switch ((
      condition.leftOperand,
      condition.rightOperand,
    )) {
      (final SimpleIdentifier id, final NullLiteral n) => (id, n),
      (final NullLiteral n, final SimpleIdentifier id) => (id, n),
      _ => (null, null),
    };
    if (identifier == null || other == null) return null;

    final element = identifier.element;

    // Only locals and parameters are tracked: a field can be read through
    // `this` or mutated by any call in the branch, so absence of the bare name
    // proves nothing.
    if (element is! LocalVariableElement &&
        element is! FormalParameterElement) {
      return null;
    }

    return (element!, identifier.name);
  }
}

/// Detects any reference to a given element.
class _UsageFinder extends RecursiveAstVisitor<void> {
  final Element target;
  bool found = false;

  _UsageFinder(this.target);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.element == target) found = true;
  }
}
