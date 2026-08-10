import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_do_notation.dart';
import '../many_lints_rule.dart';

/// Warns when an async `Do` body awaits a raw `Future` instead of extracting
/// through `$`.
///
/// `Do` tracks a block's steps through its extraction function: `$` is what
/// makes a failing step short-circuit the rest of the block. A bare
/// `await someFuture` bypasses that entirely — the future runs outside the
/// block's control, and if it throws, the exception escapes as an ordinary
/// exception rather than becoming a `Left`. This is the second of the four
/// pitfalls fpdart documents in `do_constructor_pitfalls`.
///
/// **Bad:**
/// ```dart
/// TaskEither<String, int> f(Future<int> future) => TaskEither.Do(($) async {
///   await future; // escapes the Do tracking
///   return 1;
/// });
/// ```
///
/// **Good:**
/// ```dart
/// TaskEither<String, int> f(Future<int> future) => TaskEither.Do(($) async {
///   await $(TaskEither.tryCatch(() => future, (e, s) => '$e'));
///   return 1;
/// });
/// ```
class AvoidBareAwaitInDo extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_bare_await_in_do',
    "Avoid awaiting a raw Future inside a 'Do' block.",
    correctionMessage:
        "Wrap it in an fpdart type and extract it with '\$' so a failure "
        'short-circuits the block instead of escaping it.',
  );

  AvoidBareAwaitInDo()
    : super(
        name: 'avoid_bare_await_in_do',
        description:
            'Warns when an async Do body awaits a Future directly rather than '
            'through the block\'s extraction function, escaping its tracking.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidBareAwaitInDo rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final invocation = DoInvocation.tryRead(node);
    if (invocation == null) return;

    // Only async blocks await anything; the synchronous variants (`Option.Do`,
    // `Either.Do`, the `IO*` family) cannot hit this.
    if (!invocation.isAsync) return;

    _BareAwaitFinder(rule, invocation).run();
  }
}

class _BareAwaitFinder extends DoBodyVisitor {
  final AvoidBareAwaitInDo rule;

  /// How many closures deep the visitor currently is.
  ///
  /// A closure declared inside the body has its own async context, so an
  /// `await` there was never one of the block's tracked steps. Depth is
  /// counted rather than descent being cut off, because the closure may still
  /// contain a nested `Do` whose own body must be visited.
  int _closureDepth = 0;

  _BareAwaitFinder(this.rule, super.invocation);

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _closureDepth++;
    super.visitFunctionExpression(node);
    _closureDepth--;
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    super.visitAwaitExpression(node);

    if (_closureDepth > 0) return;
    if (invocation.isExtractorCall(node.expression)) return;

    rule.reportAtNode(node);
  }
}
