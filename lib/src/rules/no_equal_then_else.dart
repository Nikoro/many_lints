import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class NoEqualThenElse extends ManyLintsRule {
  static const LintCode code = LintCode(
    'no_equal_then_else',
    'Both branches of this condition are identical.',
    correctionMessage:
        'The condition decides nothing. Make one branch differ, or remove '
        'the branching entirely.',
  );

  NoEqualThenElse()
    : super(
        name: 'no_equal_then_else',
        description:
            'Warns when the then and else branches of an if statement or '
            'conditional expression are identical.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addIfStatement(this, visitor);
    registry.addConditionalExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final NoEqualThenElse rule;

  _Visitor(this.rule);

  @override
  void visitIfStatement(IfStatement node) {
    final elseStatement = node.elseStatement;
    if (elseStatement == null) return;

    if (elseStatement is IfStatement) return;

    if (_haveSameNonEmptySource(node.thenStatement, elseStatement)) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    if (_haveSameNonEmptySource(node.thenExpression, node.elseExpression)) {
      rule.reportAtNode(node);
    }
  }

  bool _haveSameNonEmptySource(AstNode first, AstNode second) {
    final a = _sourceWithoutSingleStatementBraces(first);
    final b = _sourceWithoutSingleStatementBraces(second);

    // Edge case: `if (x) {} else {}` is usually mid-edit, so an empty pair stays silent
    if (a.isEmpty || b.isEmpty) return false;

    return a == b;
  }

  String _sourceWithoutSingleStatementBraces(AstNode node) {
    if (node case Block(:final statements) when statements.length == 1) {
      return statements.first.toSource();
    }

    if (node case Block(:final statements) when statements.isEmpty) return '';

    return node.toSource();
  }
}
