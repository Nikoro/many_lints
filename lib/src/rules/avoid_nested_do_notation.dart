import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_do_notation.dart';
import '../many_lints_rule.dart';

/// Warns when one fpdart `Do` block is nested inside another.
///
/// Each `Do` establishes its own extraction frame, and the inner block shadows
/// the outer block's `$`. Extractions written in the inner body then
/// short-circuit only the inner block, so an inner `Left`/`None` produces a
/// *successful* outer result wrapping a failed inner one instead of failing the
/// whole pipeline. This is the third of the four pitfalls fpdart documents in
/// its own `do_constructor_pitfalls` example.
///
/// A nested block is never necessary: `Do` is sugar over `flatMap`, so the
/// inner block's steps can be extracted in the outer one directly.
///
/// **Bad:**
/// ```dart
/// Option.Do(($) => Option.Do(($) => $(testOption)));
/// ```
///
/// **Good:**
/// ```dart
/// Option.Do(($) => $(testOption));
/// ```
class AvoidNestedDoNotation extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_nested_do_notation',
    "Avoid nesting one 'Do' block inside another.",
    correctionMessage:
        "Extract the inner block's steps in the outer block instead, so a "
        'failure short-circuits the whole pipeline.',
  );

  AvoidNestedDoNotation()
    : super(
        name: 'avoid_nested_do_notation',
        description:
            'Warns when an fpdart Do block is nested inside another, where the '
            'inner block short-circuits on its own instead of failing the '
            'outer pipeline.',
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
  final AvoidNestedDoNotation rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (DoInvocation.tryRead(node) == null) return;

    // Report the *inner* block, which is the one to unwrap. Walking up finds
    // the nearest enclosing `Do` regardless of how deeply the inner block sits
    // inside the outer body.
    for (
      AstNode? parent = node.parent;
      parent != null;
      parent = parent.parent
    ) {
      if (parent is InstanceCreationExpression &&
          DoInvocation.tryRead(parent) != null) {
        // Report `Option.Do` rather than the whole invocation: the callback
        // body is often many lines, and underlining all of it buries the one
        // part that matters.
        rule.reportAtNode(node.constructorName);
        return;
      }
    }
  }
}
