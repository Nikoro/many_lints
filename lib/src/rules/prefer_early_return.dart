import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a function body is a single `if` that wraps everything it does,
/// where inverting the condition and returning early would remove a level of
/// indentation.
///
/// ```dart
/// void save(User user) {
///   if (user.isValid) {
///     // twenty lines
///   }
/// }
/// ```
///
/// The reader has to hold "we are inside the valid case" for the whole body,
/// and every further condition nests one level deeper. `if (!user.isValid)
/// return;` states the precondition once and lets the rest of the function be
/// the happy path.
///
/// Only a body whose *last* statement is such an `if` is reported, and only
/// when the wrapped block is at least `min_statements` long (default 3) — for
/// a one-line body the guard version is not shorter, just differently shaped.
///
/// Never reported when the `if` has an `else`: inverting it would swap the two
/// branches rather than flatten anything. Nor when the condition is already
/// negated — `if (!map.containsKey(k))` inverts into a longer positive guard,
/// and the negation is what made the precondition obvious.
class PreferEarlyReturn extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_early_return',
    'This `if` wraps the rest of the function body.',
    correctionMessage:
        'Invert the condition and return early, so the body reads as the '
        'happy path.',
  );

  PreferEarlyReturn()
    : super(
        name: 'prefer_early_return',
        description:
            'Warns when a trailing `if` wraps a function body that an early '
            'return would flatten.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
    registry.addFunctionExpression(this, visitor);
  }
}

/// Below this, the guard form saves no nesting worth the rewrite.
const _defaultMinStatements = 3;

class _Visitor extends SimpleAstVisitor<void> {
  final PreferEarlyReturn rule;

  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) =>
      _check(node.functionExpression.body);

  @override
  void visitMethodDeclaration(MethodDeclaration node) => _check(node.body);

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // A function expression that belongs to a declaration is already checked
    // through that declaration, so skip it here to avoid reporting twice.
    if (node.parent is FunctionDeclaration) return;
    _check(node.body);
  }

  void _check(FunctionBody body) {
    if (body is! BlockFunctionBody) return;

    final statements = body.block.statements;
    // Anything before the `if` is setup the guard form would have to move or
    // duplicate, so only a body the `if` fully owns is worth reporting.
    if (statements.length != 1) return;

    final last = statements.single;
    if (last is! IfStatement) return;

    // With an `else`, inverting swaps the branches instead of flattening.
    if (last.elseStatement != null) return;

    // A `then` that already exits carries no body to flatten — that *is* the
    // guard form this rule asks for.
    final thenBlock = last.thenStatement;
    if (thenBlock is! Block) return;

    final wrapped = thenBlock.statements;
    final minStatements = rule.config.intOption(
      'min_statements',
      defaultValue: _defaultMinStatements,
    );
    if (wrapped.length < minStatements) return;

    // A pattern `if` binds variables the inverted branch cannot see, so the
    // rewrite is not mechanical.
    if (last.caseClause != null) return;

    // An already-negated condition is the case where the rewrite pays least:
    // `if (!map.containsKey(k))` inverts to a *longer* positive guard, and the
    // negation is what made the precondition obvious in the first place. This
    // exclusion came from the rule's only hit on a production codebase, where
    // the rewrite would have read worse than the code it replaced.
    if (_isNegated(last.expression)) return;

    rule.reportAtToken(last.ifKeyword);
  }

  /// Whether [condition] already reads as a negative test, so inverting it
  /// would produce the longer of the two spellings.
  bool _isNegated(Expression condition) {
    final expression = condition.unParenthesized;

    return expression is PrefixExpression &&
            expression.operator.type == TokenType.BANG ||
        expression is BinaryExpression &&
            expression.operator.type == TokenType.BANG_EQ;
  }
}
