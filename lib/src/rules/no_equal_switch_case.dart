import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when two branches of a `switch` have identical bodies.
///
/// Repeating a body states the same outcome twice, and the two copies drift:
/// one gets fixed and the other keeps the old behaviour, with nothing to show
/// that they were ever meant to agree. Sharing the patterns
/// (`case a || b => ...`) says the outcome is deliberately the same and can
/// only ever change in one place.
///
/// A wildcard or `default` branch is compared like any other. An empty body is
/// not: several empty cases in a row are how a fallthrough is written.
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
      // An empty body is a fallthrough to the next case, not a duplicate.
      if (member.statements.isEmpty) continue;

      // Neither a guarded case nor the catch-all can be merged into an `||`
      // pattern: a guard belongs to its own pattern, and the catch-all has to
      // stay last. In both, repeating a body is normal and intended.
      final isUnmergeable = switch (member) {
        SwitchDefault() => true,
        SwitchPatternCase(:final guardedPattern) =>
          guardedPattern.whenClause != null ||
              guardedPattern.pattern is WildcardPattern,
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
      // A guarded case cannot be merged into an `||` pattern — each guard
      // belongs to its own pattern — so repeating the body is the only way to
      // write it.
      if (member.guardedPattern.whenClause != null) continue;

      // The catch-all is not mergeable either: it has to stay last, and
      // folding a specific case into it would change which values it covers.
      // Its body repeating an earlier one is normal and intended.
      if (member.guardedPattern.pattern is WildcardPattern) continue;

      final body = member.expression.toSource();
      if (!seen.add(body)) {
        rule.reportAtNode(member);
      }
    }
  }
}
