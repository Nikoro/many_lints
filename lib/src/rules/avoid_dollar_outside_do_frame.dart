import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_do_notation.dart';
import '../many_lints_rule.dart';

/// Warns when a `Do` block's extraction function is called from inside a
/// nested callback rather than the block's own frame.
///
/// `$` short-circuits by throwing a private marker that the `Do` constructor
/// catches. That only works while control is still inside the block's own
/// frame: called from a `map`/`flatMap` callback, the marker unwinds through
/// machinery that never expects it, so instead of a `Left` the caller gets a
/// raw exception — or, worse, a silently wrong result. This is the fourth of
/// the four pitfalls fpdart documents in `do_constructor_pitfalls`.
///
/// **Bad:**
/// ```dart
/// Option.Do(($) => $(testOption).map(
///       (value) => $(optionOf(value)), // `$` outside the Do's own frame
///     ));
/// ```
///
/// **Good:**
/// ```dart
/// Option.Do(($) {
///   final value = $(testOption);
///   return $(optionOf(value));
/// });
/// ```
class AvoidDollarOutsideDoFrame extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_dollar_outside_do_frame',
    "Avoid calling a 'Do' block's extraction function inside a nested "
        'callback.',
    correctionMessage:
        'Extract the value in the block itself, then use it in the callback.',
  );

  AvoidDollarOutsideDoFrame()
    : super(
        name: 'avoid_dollar_outside_do_frame',
        description:
            "Warns when a Do block's extraction function is called from a "
            'nested callback, where its short-circuit unwinds through code '
            'that cannot handle it.',
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
  final AvoidDollarOutsideDoFrame rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final invocation = DoInvocation.tryRead(node);
    if (invocation == null) return;
    if (invocation.extractorName == null) return;

    // Start below the block's own callback: everything the block itself
    // contains is fine, and only what sits inside a *further* closure is not.
    invocation.body.accept(_NestedDollarFinder(rule, invocation));
  }
}

/// Finds `$` calls that sit inside a closure nested in the block's body.
class _NestedDollarFinder extends DoBodyVisitor {
  final AvoidDollarOutsideDoFrame rule;

  /// How many closures deep the visitor currently is, relative to the block's
  /// own callback.
  int _closureDepth = 0;

  _NestedDollarFinder(this.rule, super.invocation);

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _closureDepth++;
    super.visitFunctionExpression(node);
    _closureDepth--;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_report(node)) return;
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    // `$(step)` resolves to an invocation of the block's parameter, which is
    // this node type rather than a MethodInvocation.
    if (_report(node)) return;
    super.visitFunctionExpressionInvocation(node);
  }

  /// Reports [node] when it is a `$` call inside a nested closure, returning
  /// whether it was reported.
  bool _report(Expression node) {
    if (_closureDepth == 0) return false;
    if (!invocation.isExtractorCall(node)) return false;

    rule.reportAtNode(node);
    // Do not descend: a `$` nested inside this one's arguments is the same
    // mistake, and reporting it separately would double up on one fix.
    return true;
  }
}
