import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class NoEqualSwitchCase extends ManyLintsRule {
  static const LintCode code = LintCode(
    'no_equal_switch_case',
    'This branch has the same body as an earlier one.',
    correctionMessage:
        'Share the patterns with `||` so the outcome is written once.',
  );

  NoEqualSwitchCase()
    : super(
        name: 'no_equal_switch_case',
        description:
            'Warns when two branches of a switch produce identical bodies, '
            'which should share their patterns instead.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addSwitchStatement(this, visitor);
    registry.addSwitchExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final NoEqualSwitchCase rule;

  _Visitor(this.rule);

  @override
  void visitSwitchStatement(SwitchStatement node) {
    final seen = <String>{};

    for (final member in node.members) {
      // Edge case: an empty body falls through to the next case rather than duplicating it
      if (member.statements.isEmpty) continue;

      final isUnmergeable = switch (member) {
        SwitchDefault() => true,
        SwitchPatternCase(:final guardedPattern) => _isUnmergeable(
          guardedPattern,
        ),
        _ => false,
      };
      if (isUnmergeable) continue;

      final body = member.statements.map((s) => s.toSource()).join();
      if (!seen.add(body)) {
        rule.reportAtNode(member);
      }
    }
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    final seen = <String>{};

    for (final member in node.cases) {
      if (_isUnmergeable(member.guardedPattern)) continue;

      final body = member.expression.toSource();
      if (!seen.add(body)) {
        rule.reportAtNode(member);
      }
    }
  }

  // Edge case: a guard belongs to its own pattern, and the catch-all has to stay last
  bool _isUnmergeable(GuardedPattern guardedPattern) =>
      guardedPattern.whenClause != null ||
      guardedPattern.pattern is WildcardPattern;
}
