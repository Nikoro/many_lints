import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

bool containsAwait(AstNode node) {
  final finder = _AwaitFinder();
  node.accept(finder);
  return finder.found;
}

bool isMountedGuardWithReturn(Statement statement) {
  if (statement is! IfStatement) return false;
  if (!_returnsUnconditionally(statement.thenStatement)) return false;

  return _establishesUnmounted(statement.expression);
}

bool isPositiveMountedGuard(Statement statement) =>
    statement is IfStatement && _establishesMounted(statement.expression);

bool _establishesUnmounted(Expression condition) {
  final unwrapped = _unwrapParentheses(condition);

  if (unwrapped is BinaryExpression && unwrapped.operator.lexeme == '||') {
    return _establishesUnmounted(unwrapped.leftOperand) ||
        _establishesUnmounted(unwrapped.rightOperand);
  }

  if (unwrapped is! PrefixExpression) return false;
  if (unwrapped.operator.lexeme != '!') return false;

  return _isMountedRead(_unwrapParentheses(unwrapped.operand));
}

bool _establishesMounted(Expression condition) {
  final unwrapped = _unwrapParentheses(condition);

  if (unwrapped is BinaryExpression && unwrapped.operator.lexeme == '&&') {
    return _establishesMounted(unwrapped.leftOperand) ||
        _establishesMounted(unwrapped.rightOperand);
  }

  return _isMountedRead(unwrapped);
}

bool _isMountedRead(Expression expression) =>
    (expression is SimpleIdentifier && expression.name == 'mounted') ||
    (expression is PrefixedIdentifier &&
        expression.identifier.name == 'mounted') ||
    (expression is PropertyAccess && expression.propertyName.name == 'mounted');

Expression _unwrapParentheses(Expression expression) =>
    expression is ParenthesizedExpression
    ? _unwrapParentheses(expression.expression)
    : expression;

bool _returnsUnconditionally(Statement statement) {
  if (statement is ReturnStatement) return true;
  if (statement is Block) {
    final statements = statement.statements;
    return statements.length == 1 && statements.first is ReturnStatement;
  }

  return false;
}

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

bool isNegatedClosedGuard(Statement statement) {
  if (statement is! IfStatement) return false;

  final condition = statement.expression;
  if (condition is! PrefixExpression) return false;
  if (condition.operator.lexeme != '!') return false;

  return _isClosedCheck(condition.operand);
}

bool _isClosedCheck(Expression expression) =>
    (expression is SimpleIdentifier && expression.name == 'isClosed') ||
    (expression is PrefixedIdentifier &&
        expression.identifier.name == 'isClosed') ||
    (expression is PropertyAccess &&
        expression.propertyName.name == 'isClosed');

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
