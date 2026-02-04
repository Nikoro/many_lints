import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'package:many_lints/src/type_checker.dart';
import 'package:many_lints/src/utils/helpers.dart';

/// Collects hook invocations from AST nodes.
class _HookExpressionsGatherer extends GeneralizingAstVisitor<void> {
  final List<InvocationExpression> _hookExpressions = [];

  static List<InvocationExpression> gather(AstNode node) {
    final visitor = _HookExpressionsGatherer();
    node.accept(visitor);
    return visitor._hookExpressions;
  }

  // use + upper case letter to avoid cases like "user"
  static final _isHookRegex = RegExp('^_?use[0-9A-Z]');

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final body = maybeHookBuilderBody(node);
    if (body != null) {
      // this is a hook builder, so it has a new hook context for used hooks: stop recursing
      return;
    }
    // It is not a hook builder, let's continue searching
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitInvocationExpression(InvocationExpression node) {
    if (_isHookRegex.hasMatch(node.beginToken.lexeme)) {
      _hookExpressions.add(node);
    }

    super.visitInvocationExpression(node);
  }
}

/// Returns all hook expressions found within an AST node.
List<InvocationExpression> getAllInnerHookExpressions(AstNode node) {
  return _HookExpressionsGatherer.gather(node);
}

/// Given an instance creation, returns the builder function body if the node is a HookBuilder.
FunctionBody? maybeHookBuilderBody(InstanceCreationExpression node) {
  final classElement = node.constructorName.type.element;
  if (classElement == null) return null;

  const hookBuilderChecker = TypeChecker.any([
    TypeChecker.fromName('HookBuilder', packageName: 'flutter_hooks'),
    TypeChecker.fromName('HookConsumer', packageName: 'hooks_riverpod'),
  ]);

  if (!hookBuilderChecker.isExactly(classElement)) return null;

  final builderParameter = node.argumentList.arguments
      .whereType<NamedExpression>()
      .firstWhereOrNull((e) => e.name.label.name == 'builder');
  if (builderParameter case NamedExpression(
    expression: FunctionExpression(:final body),
  )) {
    return body;
  }

  return null;
}
