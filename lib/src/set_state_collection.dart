import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class SetStateCollector extends RecursiveAstVisitor<void> {
  final List<MethodInvocation> calls = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'setState') {
      calls.add(node);
    }
    super.visitMethodInvocation(node);
  }

  // Edge case: setState inside a closure belongs to a different logical scope
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}
