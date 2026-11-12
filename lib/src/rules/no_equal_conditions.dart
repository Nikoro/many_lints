import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

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
    if (_isElseIfOfAnEnclosingChain(node)) return;

    final seen = <String>{};

    for (IfStatement? current = node; current != null;) {
      // Edge case: an `if-case` binds variables, so two alike spellings may test different things
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

  bool _isElseIfOfAnEnclosingChain(IfStatement node) => switch (node.parent) {
    IfStatement(:final elseStatement) => identical(elseStatement, node),
    _ => false,
  };
}
