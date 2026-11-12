import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class AvoidThrowInCatchBlock extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_throw_in_catch_block',
    'Avoid using throw inside a catch block.',
    correctionMessage:
        'Use Error.throwWithStackTrace() to preserve the stack trace.',
  );

  AvoidThrowInCatchBlock()
    : super(
        name: 'avoid_throw_in_catch_block',
        description:
            'Warns when a throw expression is used inside a catch block.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addTryStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidThrowInCatchBlock rule;

  _Visitor(this.rule);

  @override
  void visitTryStatement(TryStatement node) {
    for (final catchClause in node.catchClauses) {
      final throwFinder = _ThrowFinder(rule);
      catchClause.body.visitChildren(throwFinder);
    }
  }
}

class _ThrowFinder extends RecursiveAstVisitor<void> {
  final AvoidThrowInCatchBlock rule;

  _ThrowFinder(this.rule);

  @override
  void visitThrowExpression(ThrowExpression node) {
    rule.reportAtNode(node);
    super.visitThrowExpression(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}
