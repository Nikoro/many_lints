import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import './ast_node_analysis.dart';
import './type_checker.dart';

final hookNameRegex = RegExp('^_?use[0-9A-Z]');

bool isHookInvocation(AstNode node) {
  if (!hookNameRegex.hasMatch(node.beginToken.lexeme)) return false;

  final libraryUri = switch (node) {
    MethodInvocation(:final methodName) => methodName.element?.library?.uri,
    FunctionExpressionInvocation(function: Identifier(:final element)) =>
      element?.library?.uri,
    InstanceCreationExpression(:final constructorName) =>
      constructorName.element?.library.uri,
    _ => null,
  };
  if (libraryUri?.scheme == 'dart') return false;
  if (libraryUri?.scheme == 'package' &&
      const {
        'flutter',
        'flutter_web_plugins',
      }.contains(libraryUri?.pathSegments.firstOrNull)) {
    return false;
  }
  return true;
}

class _HookExpressionsGatherer extends GeneralizingAstVisitor<void> {
  final List<InvocationExpression> _hookExpressions = [];

  static List<InvocationExpression> gather(AstNode node) {
    final visitor = _HookExpressionsGatherer();
    node.accept(visitor);
    return visitor._hookExpressions;
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // Edge case: a hook builder opens its own hook context, so its hooks are not ours
    if (maybeHookBuilderBody(node) != null) return;
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitInvocationExpression(InvocationExpression node) {
    if (isHookInvocation(node)) {
      _hookExpressions.add(node);
    }

    super.visitInvocationExpression(node);
  }
}

List<InvocationExpression> getAllInnerHookExpressions(AstNode node) {
  return _HookExpressionsGatherer.gather(node);
}

FunctionBody? maybeHookBuilderBody(InstanceCreationExpression node) {
  final classElement = node.constructorName.type.element;
  if (classElement == null) return null;

  const hookBuilderChecker = TypeChecker.any([
    TypeChecker.fromName('HookBuilder', packageName: 'flutter_hooks'),
    TypeChecker.fromName('HookConsumer', packageName: 'hooks_riverpod'),
  ]);

  if (!hookBuilderChecker.isExactly(classElement)) return null;

  final builderParameter = node.argumentList.arguments
      .whereType<NamedArgument>()
      .firstWhereOrNull((e) => e.name.lexeme == 'builder');
  if (builderParameter case NamedArgument(
    argumentExpression: FunctionExpression(:final body),
  )) {
    return body;
  }

  return null;
}
