import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when an `if` statement contains nothing but another `if`.
///
/// Two nested conditions with no `else` on either level and no other
/// statement between them are just a conjunction written across two
/// blocks. Merging them with `&&` removes a level of indentation and makes
/// the real condition readable in one line.
class AvoidCollapsibleIf extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_collapsible_if',
    'This if statement can be merged with the nested one.',
    correctionMessage: "Combine both conditions with '&&'.",
  );

  AvoidCollapsibleIf()
    : super(
        name: 'avoid_collapsible_if',
        description:
            'Warns when an if statement contains only another if statement '
            'and both can be merged with &&.',
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
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidCollapsibleIf rule;

  _Visitor(this.rule);

  @override
  void visitIfStatement(IfStatement node) {
    // An else branch on the outer if means the nesting carries meaning.
    if (node.elseStatement != null) return;

    // A case clause (`if (x case P)`) cannot be merged with `&&`.
    if (node.caseClause != null) return;

    final inner = _soleNestedIf(node.thenStatement);
    if (inner == null) return;

    if (inner.elseStatement != null) return;
    if (inner.caseClause != null) return;

    rule.reportAtToken(node.ifKeyword);
  }

  /// Returns the nested `if` when [statement] is exactly one `if` — either
  /// written directly or as the only statement of a block.
  IfStatement? _soleNestedIf(Statement statement) => switch (statement) {
    IfStatement() => statement,
    Block(:final statements) when statements.length == 1 =>
      statements.first is IfStatement ? statements.first as IfStatement : null,
    _ => null,
  };
}
