import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Returns true if [node] contains an `await` expression
/// (stopping at function boundaries).
bool containsAwait(AstNode node) {
  final finder = _AwaitFinder();
  node.accept(finder);
  return finder.found;
}

/// Returns true if [statement] is a mounted guard pattern:
/// `if (!ref.mounted) return;`, `if (!mounted) return;`,
/// or `if (!context.mounted) return;`.
///
/// A disjunction counts too — `if (!mounted || failed) return;`. The early
/// return fires whenever `mounted` is false, whatever the other operand says,
/// so reaching the line below still proves the widget is mounted. A
/// *conjunction* (`if (!mounted && failed) return;`) proves nothing: it falls
/// through while unmounted whenever `failed` is false.
bool isMountedGuardWithReturn(Statement statement) {
  if (statement is! IfStatement) return false;
  if (!_returnsUnconditionally(statement.thenStatement)) return false;

  return _establishesUnmounted(statement.expression);
}

/// Returns true if [statement] is the positive wrapper form of the guard —
/// `if (mounted) { ... }` — where the work sits inside the then-branch rather
/// than after an early return.
///
/// This is what you write when there is nothing to do after the guard, so an
/// early `return` would be noise. It is as safe as the early-return form and
/// just as common, so a rule that recognises only the latter reports idiomatic
/// code.
///
/// A conjunction counts — `if (mounted && ready) { ... }` — because entering
/// the branch requires `mounted` to be true. A disjunction does not: with
/// `if (mounted || ready)` the branch also runs while unmounted.
///
/// Only the then-branch is covered. An `else` runs precisely when the guard
/// failed, so anything in it is as unguarded as before.
bool isPositiveMountedGuard(Statement statement) =>
    statement is IfStatement && _establishesMounted(statement.expression);

/// Whether reaching the statement after an early return proves `mounted` is
/// false — that is, whether the condition is true whenever `mounted` is false.
bool _establishesUnmounted(Expression condition) {
  final unwrapped = _unwrapParentheses(condition);

  // `a || b` returns whenever either side does, so one negated `mounted`
  // operand is enough.
  if (unwrapped is BinaryExpression && unwrapped.operator.lexeme == '||') {
    return _establishesUnmounted(unwrapped.leftOperand) ||
        _establishesUnmounted(unwrapped.rightOperand);
  }

  if (unwrapped is! PrefixExpression) return false;
  if (unwrapped.operator.lexeme != '!') return false;

  return _isMountedRead(_unwrapParentheses(unwrapped.operand));
}

/// Whether entering the then-branch proves `mounted` is true.
bool _establishesMounted(Expression condition) {
  final unwrapped = _unwrapParentheses(condition);

  // `a && b` only enters when both hold, so one `mounted` operand is enough.
  if (unwrapped is BinaryExpression && unwrapped.operator.lexeme == '&&') {
    return _establishesMounted(unwrapped.leftOperand) ||
        _establishesMounted(unwrapped.rightOperand);
  }

  return _isMountedRead(unwrapped);
}

/// Whether [expression] reads a `mounted` property, in any of the forms
/// `mounted`, `this.mounted`, `context.mounted`, or `ref.mounted`.
bool _isMountedRead(Expression expression) =>
    (expression is SimpleIdentifier && expression.name == 'mounted') ||
    (expression is PrefixedIdentifier &&
        expression.identifier.name == 'mounted') ||
    (expression is PropertyAccess && expression.propertyName.name == 'mounted');

/// Strips redundant parentheses so `if (!(mounted))` reads like `if (!mounted)`.
Expression _unwrapParentheses(Expression expression) =>
    expression is ParenthesizedExpression
    ? _unwrapParentheses(expression.expression)
    : expression;

/// Whether [statement] is a bare `return;` or a block containing only one.
bool _returnsUnconditionally(Statement statement) {
  if (statement is ReturnStatement) return true;
  if (statement is Block) {
    final statements = statement.statements;
    return statements.length == 1 && statements.first is ReturnStatement;
  }

  return false;
}

/// Returns true if [statement] guards against a closed bloc and returns:
/// `if (isClosed) return;` or `if (this.isClosed) return;`.
bool isClosedGuardWithReturn(Statement statement) {
  if (statement is! IfStatement) return false;
  if (!_isClosedCheck(statement.expression)) return false;

  final thenStatement = statement.thenStatement;
  if (thenStatement is ReturnStatement) return true;
  if (thenStatement is Block) {
    final stmts = thenStatement.statements;
    if (stmts.length == 1 && stmts.first is ReturnStatement) return true;
  }

  return false;
}

/// Returns true if [statement] is `if (!isClosed) { ... }` — the inverted
/// form, where the guarded work lives in the then-branch instead of after
/// an early return.
bool isNegatedClosedGuard(Statement statement) {
  if (statement is! IfStatement) return false;

  final condition = statement.expression;
  if (condition is! PrefixExpression) return false;
  if (condition.operator.lexeme != '!') return false;

  return _isClosedCheck(condition.operand);
}

/// Whether [expression] reads an `isClosed` property, in any of the forms
/// `isClosed`, `this.isClosed`, or `bloc.isClosed`.
bool _isClosedCheck(Expression expression) =>
    (expression is SimpleIdentifier && expression.name == 'isClosed') ||
    (expression is PrefixedIdentifier &&
        expression.identifier.name == 'isClosed') ||
    (expression is PropertyAccess &&
        expression.propertyName.name == 'isClosed');

/// Finds `await` expressions, stopping at function boundaries.
class _AwaitFinder extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    found = true;
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}
