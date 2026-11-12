import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../type_checker.dart';

class AvoidRedundantAsync extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_redundant_async',
    'This function is `async` but never awaits.',
    correctionMessage:
        'Remove `async` and return the future directly, or await inside it.',
  );

  AvoidRedundantAsync()
    : super(
        name: 'avoid_redundant_async',
        description:
            'Warns when an async function neither awaits nor throws and every '
            'return path already produces a compatible Future.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, context);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidRedundantAsync rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  static const _futureChecker = TypeChecker.fromUrl('dart:async#Future');

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) => _check(
    node.functionExpression.body,
    node.declaredFragment?.element.returnType,
    node.name,
  );

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.metadata.any((a) => a.name.name == 'override')) return;

    _check(node.body, node.declaredFragment?.element.returnType, node.name);
  }

  void _check(FunctionBody body, DartType? returnType, Token name) {
    if (!body.isAsynchronous) return;

    if (body.isGenerator) return;

    final collector = _AwaitCollector();
    body.accept(collector);
    if (collector.foundAwait || collector.foundThrow) return;

    if (returnType == null) return;
    final returned = _returnedExpressions(body);
    if (returned == null || returned.isEmpty) return;

    if (!returned.every((e) => _isFutureOf(e, returnType))) return;

    rule.reportAtToken(name);
  }

  bool _isFutureOf(Expression expression, DartType returnType) {
    final expressionType = expression.staticType;
    return expressionType != null &&
        expressionType is! DynamicType &&
        expressionType is! NeverType &&
        _futureChecker.isAssignableFromType(expressionType) &&
        context.typeSystem.isAssignableTo(
          expressionType,
          returnType,
          strictCasts: false,
        );
  }

  List<Expression>? _returnedExpressions(FunctionBody body) {
    if (body case ExpressionFunctionBody(:final expression)) {
      return [expression];
    }
    if (body is! BlockFunctionBody) return null;

    final statements = body.block.statements;
    if (statements.isEmpty || statements.last is! ReturnStatement) return null;
    final last = statements.last as ReturnStatement;
    if (last.expression == null) return null;

    final collector = _ReturnCollector();
    body.block.accept(collector);
    if (collector.hasBareReturn) return null;
    return collector.expressions;
  }
}

class _AwaitCollector extends RecursiveAstVisitor<void> {
  bool foundAwait = false;
  bool foundThrow = false;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    foundAwait = true;
  }

  @override
  void visitForStatement(ForStatement node) {
    if (node.awaitKeyword != null) foundAwait = true;
    super.visitForStatement(node);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    foundThrow = true;
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}

class _ReturnCollector extends RecursiveAstVisitor<void> {
  final expressions = <Expression>[];
  bool hasBareReturn = false;

  @override
  void visitReturnStatement(ReturnStatement node) {
    final expression = node.expression;
    if (expression == null) {
      hasBareReturn = true;
    } else {
      expressions.add(expression);
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}
