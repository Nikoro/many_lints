import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a function executes more statements than the configured budget.
///
/// This is the counterpart to `avoid_long_functions`, measuring what the
/// function *does* rather than how much room it takes. The two disagree in
/// exactly the useful cases: a function of twenty short statements is long by
/// lines and long by work, while one holding a single wide widget tree is long
/// by lines only, and splitting it would help nobody.
///
/// The limit is `max_statements`, defaulting to 25. Statements are counted
/// through nested blocks, so a loop body counts toward the function that owns
/// it, but a nested function expression is counted on its own — a callback is
/// separate work, not more of the enclosing function's.
class MaxStatements extends ManyLintsRule {
  static const LintCode code = LintCode(
    'max_statements',
    'This function executes {0} statements, over the limit of {1}.',
    correctionMessage:
        'Extract a step that has its own name, or raise max_statements.',
  );

  MaxStatements()
    : super(
        name: 'max_statements',
        description:
            'Warns when a function executes more statements than the '
            'configured budget.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
    registry.addConstructorDeclaration(this, visitor);
  }
}

/// Enough for a function doing one thing thoroughly.
const _defaultMaxStatements = 25;

class _Visitor extends SimpleAstVisitor<void> {
  final MaxStatements rule;

  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) =>
      _check(node.functionExpression.body, node.name);

  @override
  void visitMethodDeclaration(MethodDeclaration node) =>
      _check(node.body, node.name);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) =>
      _check(node.body, node.name, fallback: node);

  void _check(FunctionBody body, Token? name, {AstNode? fallback}) {
    if (body is! BlockFunctionBody) return;

    final maxStatements = rule.config.intOption(
      'max_statements',
      defaultValue: _defaultMaxStatements,
    );

    final counter = _StatementCounter();
    body.block.accept(counter);

    final count = counter.count;
    if (count <= maxStatements) return;

    final arguments = ['$count', '$maxStatements'];
    if (name != null) {
      rule.reportAtToken(name, arguments: arguments);
    } else if (fallback != null) {
      rule.reportAtNode(fallback, arguments: arguments);
    }
  }
}

/// Counts executable statements, descending through blocks but not into
/// nested function bodies.
class _StatementCounter extends RecursiveAstVisitor<void> {
  int count = 0;

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // A callback is its own unit of work, and is measured when the rule
    // reaches its own declaration.
  }

  @override
  void visitBlock(Block node) {
    // A block is punctuation, not work; its statements are counted as they
    // are visited.
    super.visitBlock(node);
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    count++;
    super.visitExpressionStatement(node);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    count++;
    super.visitVariableDeclarationStatement(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    count++;
    super.visitIfStatement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    count++;
    super.visitForStatement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    count++;
    super.visitWhileStatement(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    count++;
    super.visitDoStatement(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    count++;
    super.visitSwitchStatement(node);
  }

  @override
  void visitTryStatement(TryStatement node) {
    count++;
    super.visitTryStatement(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    count++;
    super.visitReturnStatement(node);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    count++;
    super.visitYieldStatement(node);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    count++;
    super.visitBreakStatement(node);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    count++;
    super.visitContinueStatement(node);
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    count++;
    super.visitAssertStatement(node);
  }
}
