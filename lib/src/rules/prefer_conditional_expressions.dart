import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class PreferConditionalExpressions extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_conditional_expressions',
    'This if/else only chooses between two values.',
    correctionMessage: 'Write it as a conditional expression.',
  );

  PreferConditionalExpressions()
    : super(
        name: 'prefer_conditional_expressions',
        description:
            'Warns when an if/else only assigns or returns two values.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addIfStatement(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferConditionalExpressions rule;

  _Visitor(this.rule);

  @override
  void visitIfStatement(IfStatement node) {
    final elseStatement = node.elseStatement;
    if (elseStatement == null) return;
    // Edge case: an `else if` chain is a sequence of tests, not a two-way choice
    if (elseStatement is IfStatement) return;
    // Edge case: a pattern `if` binds variables a conditional expression cannot
    if (node.caseClause != null) return;

    final thenSingle = _singleStatement(node.thenStatement);
    final elseSingle = _singleStatement(elseStatement);
    if (thenSingle == null || elseSingle == null) return;

    if (_bothReturn(thenSingle, elseSingle) ||
        _bothAssignTheSameTarget(thenSingle, elseSingle)) {
      rule.reportAtToken(node.ifKeyword);
    }
  }

  Statement? _singleStatement(Statement branch) => switch (branch) {
    Block(statements: [final only]) => only,
    Block() => null,
    _ => branch,
  };

  bool _bothReturn(Statement a, Statement b) =>
      a is ReturnStatement &&
      a.expression != null &&
      b is ReturnStatement &&
      b.expression != null;

  bool _bothAssignTheSameTarget(Statement a, Statement b) {
    if (a is! ExpressionStatement || b is! ExpressionStatement) return false;

    final left = a.expression;
    final right = b.expression;
    if (left is! AssignmentExpression || right is! AssignmentExpression) {
      return false;
    }
    if (left.operator.lexeme != right.operator.lexeme) return false;

    return left.leftHandSide.toSource() == right.leftHandSide.toSource();
  }
}
