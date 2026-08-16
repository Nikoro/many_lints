import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when control flow is nested more deeply than the configured budget.
///
/// This is the non-widget counterpart to `avoid_deep_widget_nesting`. Each
/// level of `if`, `for`, `while`, `try` or `switch` is another condition the
/// reader has to hold to know why a line runs at all, and the innermost
/// statement of a five-level nest is reachable only through a path nobody can
/// state out loud.
///
/// Depth is usually the more actionable signal than complexity: an early
/// return, a guard clause or an extracted method removes a whole level, where
/// a high complexity count says only that something is wrong.
///
/// The limit is `max_depth`, defaulting to 4. Only statements that introduce a
/// new block of control flow are counted — a `case` body inside its `switch`
/// is one level, not two — and a nested function starts its own count, since
/// its body is not reached through the enclosing nest.
class AvoidDeepNesting extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_deep_nesting',
    'This is nested {0} levels deep, over the limit of {1}.',
    correctionMessage:
        'Return early, invert a condition, or extract the inner block into a '
        'method that names it.',
  );

  AvoidDeepNesting()
    : super(
        name: 'avoid_deep_nesting',
        description:
            'Warns when control flow is nested more deeply than the '
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

/// Four levels is a guard, a loop, a branch and the work — past that a reader
/// cannot state why the innermost line runs.
const _defaultMaxDepth = 4;

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidDeepNesting rule;

  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) =>
      _check(node.functionExpression.body);

  @override
  void visitMethodDeclaration(MethodDeclaration node) => _check(node.body);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) =>
      _check(node.body);

  void _check(FunctionBody body) {
    if (body is! BlockFunctionBody) return;

    final maxDepth = rule.config.intOption(
      'max_depth',
      defaultValue: _defaultMaxDepth,
    );

    final finder = _DeepestNestFinder(maxDepth: maxDepth);
    body.block.accept(finder);

    final deepest = finder.report;
    if (deepest == null) return;

    // Reported at the statement that first crosses the limit, so the
    // diagnostic lands on the block worth extracting rather than on the
    // innermost line, and one over-nested function reports once.
    rule.reportAtToken(
      deepest.token,
      arguments: ['${finder.deepestDepth}', '$maxDepth'],
    );
  }
}

/// The statement that first crossed the budget, and how deep the nest went.
class _Report {
  const _Report(this.token);

  final Token token;
}

/// Finds the first statement past [maxDepth] and the deepest nesting reached.
///
/// A nested function is skipped: its body is not reached through the enclosing
/// nest, so counting it would blame a function for the shape of its callback.
class _DeepestNestFinder extends RecursiveAstVisitor<void> {
  _DeepestNestFinder({required this.maxDepth});

  final int maxDepth;

  _Report? report;
  int deepestDepth = 0;

  int _current = 0;

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitIfStatement(IfStatement node) {
    // An `else if` is a sibling branch, not another level: it is written flat
    // and reads flat, so counting it as nesting would report every long
    // dispatch chain.
    if (node.parent is IfStatement &&
        (node.parent! as IfStatement).elseStatement == node) {
      super.visitIfStatement(node);
      return;
    }

    _enter(node.ifKeyword, () => super.visitIfStatement(node));
  }

  @override
  void visitForStatement(ForStatement node) =>
      _enter(node.forKeyword, () => super.visitForStatement(node));

  @override
  void visitWhileStatement(WhileStatement node) =>
      _enter(node.whileKeyword, () => super.visitWhileStatement(node));

  @override
  void visitDoStatement(DoStatement node) =>
      _enter(node.doKeyword, () => super.visitDoStatement(node));

  @override
  void visitSwitchStatement(SwitchStatement node) =>
      _enter(node.switchKeyword, () => super.visitSwitchStatement(node));

  @override
  void visitTryStatement(TryStatement node) =>
      _enter(node.tryKeyword, () => super.visitTryStatement(node));

  void _enter(Token token, void Function() visitChildren) {
    _current++;
    if (_current > deepestDepth) deepestDepth = _current;
    if (_current > maxDepth) report ??= _Report(token);

    visitChildren();
    _current--;
  }
}
