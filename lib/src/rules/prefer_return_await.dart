import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class PreferReturnAwait extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_return_await',
    'Missing await on returned Future inside try-catch block.',
    correctionMessage: 'Add await before the returned expression.',
  );

  PreferReturnAwait()
    : super(
        name: 'prefer_return_await',
        description:
            'Warns when a Future is returned without await inside a '
            'try-catch block.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addReturnStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferReturnAwait rule;

  _Visitor(this.rule);

  @override
  void visitReturnStatement(ReturnStatement node) {
    final expression = node.expression;
    if (expression == null) return;

    if (expression is AwaitExpression) return;

    final type = expression.staticType;
    if (type == null || !_isFutureType(type)) return;

    if (!_isInsideTryCatch(node)) return;

    if (!_isEnclosingFunctionAsync(node)) return;

    rule.reportAtNode(expression);
  }

  static bool _isFutureType(DartType type) {
    if (type is! InterfaceType) return false;
    final name = type.element.name;
    return name == 'Future' || name == 'FutureOr';
  }

  static bool _isInsideTryCatch(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is FunctionExpression ||
          current is FunctionDeclaration ||
          current is MethodDeclaration) {
        return false;
      }

      if (current is TryStatement) {
        return _isInTryBodyOrCatch(node, current);
      }

      current = current.parent;
    }
    return false;
  }

  static bool _isInTryBodyOrCatch(AstNode node, TryStatement tryStatement) {
    if (_isDescendantOf(node, tryStatement.body)) return true;

    for (final catchClause in tryStatement.catchClauses) {
      if (_isDescendantOf(node, catchClause)) return true;
    }

    return false;
  }

  static bool _isDescendantOf(AstNode node, AstNode ancestor) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current == ancestor) return true;
      current = current.parent;
    }
    return false;
  }

  static bool _isEnclosingFunctionAsync(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is FunctionExpression) {
        return current.body.isAsynchronous;
      }
      if (current is MethodDeclaration) {
        return current.body.isAsynchronous;
      }
      current = current.parent;
    }
    return false;
  }
}
