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
bool isMountedGuardWithReturn(Statement statement) {
  if (statement is! IfStatement) return false;
  final condition = statement.expression;

  if (condition is! PrefixExpression) return false;
  if (condition.operator.lexeme != '!') return false;

  final operand = condition.operand;
  final isMountedCheck =
      (operand is PrefixedIdentifier && operand.identifier.name == 'mounted') ||
      (operand is PropertyAccess && operand.propertyName.name == 'mounted') ||
      (operand is SimpleIdentifier && operand.name == 'mounted');

  if (!isMountedCheck) return false;

  final thenStatement = statement.thenStatement;
  if (thenStatement is ReturnStatement) return true;
  if (thenStatement is Block) {
    final stmts = thenStatement.statements;
    if (stmts.length == 1 && stmts.first is ReturnStatement) return true;
  }

  return false;
}

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
