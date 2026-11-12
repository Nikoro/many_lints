import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

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

    rule.reportAtToken(
      deepest.token,
      arguments: ['${finder.deepestDepth}', '$maxDepth'],
    );
  }
}

class _Report {
  const _Report(this.token);

  final Token token;
}

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
    // Edge case: an else-if is a flat sibling branch, not another nesting level
    if (_isElseIf(node)) {
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

  static bool _isElseIf(IfStatement node) => switch (node.parent) {
    IfStatement(:final elseStatement) => elseStatement == node,
    _ => false,
  };

  void _enter(Token token, void Function() visitChildren) {
    _current++;
    if (_current > deepestDepth) deepestDepth = _current;
    // Edge case: the first crossing marks the block worth extracting, once per function
    if (_current > maxDepth) report ??= _Report(token);

    visitChildren();
    _current--;
  }
}
