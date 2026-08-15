import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a function is marked `async` but never awaits.
///
/// `async` without `await` still changes behaviour: the body no longer runs
/// synchronously up to its first suspension, the result is wrapped in an extra
/// `Future`, and a throw becomes a rejected future rather than a synchronous
/// error. None of that is what the author wanted when the keyword is simply
/// left over from a body that used to await.
///
/// A function already returning a `Future` needs no `async` to be awaited by
/// its callers, so removing the keyword is safe and keeps the signature.
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
            'Warns when a function is marked async without awaiting, which '
            'adds a wrapping Future and defers the body for nothing.',
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
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidRedundantAsync rule;

  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) =>
      _check(node.functionExpression.body, node.name);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // An override's `async` may be required to satisfy the supertype's
    // return type, and removing it is not the caller's decision to make.
    if (node.metadata.any((a) => a.name.name == 'override')) return;

    _check(node.body, node.name);
  }

  void _check(FunctionBody body, Token name) {
    if (!body.isAsynchronous) return;

    // `async*` is a stream generator; the keyword is what makes it one.
    if (body.isGenerator) return;

    final collector = _AwaitCollector();
    body.accept(collector);
    if (collector.found) return;

    // Without a value to hand back, dropping `async` would turn a
    // `Future<void>` into `void` — a signature change rather than a cleanup.
    // An expression body always produces one; a block body needs a `return`.
    final producesAValue =
        body is ExpressionFunctionBody || collector.returnsAValue;
    if (!producesAValue) return;

    rule.reportAtToken(name);
  }
}

/// Looks for an `await` belonging to this function body.
class _AwaitCollector extends RecursiveAstVisitor<void> {
  bool found = false;
  bool returnsAValue = false;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    found = true;
  }

  /// `await for` suspends just as `await` does.
  @override
  void visitForStatement(ForStatement node) {
    if (node.awaitKeyword != null) found = true;
    super.visitForStatement(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    if (node.expression != null) returnsAValue = true;
    super.visitReturnStatement(node);
  }

  /// A nested function's `await` belongs to that function, not to this one.
  @override
  void visitFunctionExpression(FunctionExpression node) {}
}
