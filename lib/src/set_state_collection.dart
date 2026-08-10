import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Collects `setState` calls belonging to one method body.
///
/// The visitor deliberately does *not* descend into closures or local
/// functions: a `setState` inside a callback runs at a different time than the
/// surrounding method, so merging it with the method's own calls would change
/// behaviour. Shared between the rule that reports redundant calls and the fix
/// that merges them, so both agree on exactly which calls are in scope.
class SetStateCollector extends RecursiveAstVisitor<void> {
  /// The `setState` invocations found, in source order.
  final List<MethodInvocation> calls = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'setState') {
      calls.add(node);
    }
    super.visitMethodInvocation(node);
  }

  // Stop at nested function boundaries — setState inside closures
  // belongs to a different logical scope.
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}
