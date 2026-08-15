import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when an `if`/`else if` chain tests the same condition twice.
///
/// The second test can never be reached: the first branch already took every
/// case it would have matched. Whatever the repeated branch does is dead code,
/// and the case it was meant to handle silently falls through to `else`.
///
/// It is a copy-paste result — a branch duplicated and its body edited while
/// its condition was left alone.
class NoEqualConditions extends ManyLintsRule {
  static const LintCode code = LintCode(
    'no_equal_conditions',
    'This condition is already tested earlier in the chain.',
    correctionMessage:
        'Change it to the condition that was meant, or remove the branch.',
  );

  NoEqualConditions()
    : super(
        name: 'no_equal_conditions',
        description:
            'Warns when an if/else-if chain repeats a condition, making the '
            'later branch unreachable.',
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
  final NoEqualConditions rule;

  _Visitor(this.rule);

  @override
  void visitIfStatement(IfStatement node) {
    // Only start at the head of a chain, or every `else if` would be walked
    // again as its own chain and report the same pair twice.
    if (node.parent case IfStatement(
      elseStatement: final elseBranch,
    ) when identical(elseBranch, node)) {
      return;
    }

    final seen = <String>{};

    for (IfStatement? current = node; current != null;) {
      // A pattern case (`if (x case ...)`) binds variables, so two spellings
      // that read alike are not necessarily the same test.
      if (current.caseClause != null) return;

      final condition = current.expression.toSource();
      if (!seen.add(condition)) {
        rule.reportAtNode(current.expression);
      }

      current = switch (current.elseStatement) {
        IfStatement() && final next => next,
        _ => null,
      };
    }
  }
}
