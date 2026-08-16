import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when an `if`/`else` does nothing but assign or return two values,
/// where a conditional expression says the same thing in one line.
///
/// ```dart
/// if (isActive) {
///   label = 'On';
/// } else {
///   label = 'Off';
/// }
/// ```
///
/// Six lines to choose between two strings buries the one thing that varies.
/// `label = isActive ? 'On' : 'Off';` puts the choice and both outcomes on one
/// line, and makes it obvious that every path assigns exactly once — which the
/// block form only implies.
///
/// Only the two shapes where the rewrite is exact are reported: both branches
/// return, or both assign to the same target with the same operator. Anything
/// else — a branch with two statements, different targets, a missing `else` —
/// is left alone, since collapsing it would change what the code does.
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
    // An `else if` chain is a sequence of tests, not a two-way choice.
    if (elseStatement is IfStatement) return;
    // A pattern `if` binds variables a conditional expression cannot.
    if (node.caseClause != null) return;

    final thenSingle = _singleStatement(node.thenStatement);
    final elseSingle = _singleStatement(elseStatement);
    if (thenSingle == null || elseSingle == null) return;

    if (_bothReturn(thenSingle, elseSingle) ||
        _bothAssignTheSameTarget(thenSingle, elseSingle)) {
      rule.reportAtToken(node.ifKeyword);
    }
  }

  /// The single statement a branch holds, unwrapping a one-statement block.
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

  /// Whether both branches assign to the same target with the same operator.
  ///
  /// The operator must match too: `x = a` in one branch and `x += b` in the
  /// other are not a choice between two values.
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
