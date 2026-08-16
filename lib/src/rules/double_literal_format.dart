import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../double_literal_parts.dart';
import '../many_lints_rule.dart';

/// Warns when a double literal is written with a redundant leading or trailing
/// zero.
///
/// `.5` and `0.50` denote the same number, so the spelling carries no
/// information and only costs the reader a moment deciding whether it does.
/// The bare-dot form is the one that misleads: `.5` reads as a member access
/// until the eye reaches the digit, and a dropped dot turns `.5` into a name.
///
/// Three defects are reported separately, so a project can keep the ones it
/// cares about:
///
/// - a missing leading zero (`.5`), reported unless `leading_zero: false`
/// - a redundant leading zero (`00.5`), always reported
/// - a trailing zero in the fraction (`0.50`), reported unless
///   `trailing_zero: false`
///
/// `dart format` does not touch any of them, so this rule does not fight the
/// formatter.
class DoubleLiteralFormat extends ManyLintsRule {
  static const LintCode code = LintCode(
    'double_literal_format',
    'This double literal has {0}.',
    correctionMessage: 'Write it as {1}.',
  );

  DoubleLiteralFormat()
    : super(
        name: 'double_literal_format',
        description:
            'Warns when a double literal has a missing or redundant leading '
            'zero, or a redundant trailing zero.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addDoubleLiteral(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final DoubleLiteralFormat rule;

  _Visitor(this.rule);

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    final lexeme = node.literal.lexeme;
    final parts = DoubleLiteralParts.tryParse(lexeme);
    if (parts == null) return;

    final checkLeading = rule.config.boolOption(
      'leading_zero',
      defaultValue: true,
    );
    final checkTrailing = rule.config.boolOption(
      'trailing_zero',
      defaultValue: true,
    );

    // A redundant leading zero (`00.5`) is reported even with `leading_zero`
    // off: that option governs whether `.5` must be written `0.5`, which is a
    // style choice, while `00.5` is a typo under either style.
    final problem = switch (parts) {
      _ when parts.hasRedundantLeadingZeros => _Problem.redundantLeadingZero,
      _ when checkLeading && parts.hasMissingLeadingZero =>
        _Problem.missingLeadingZero,
      _ when checkTrailing && parts.hasTrailingZeros =>
        _Problem.redundantTrailingZero,
      _ => null,
    };
    if (problem == null) return;

    rule.reportAtNode(
      node,
      arguments: [problem.description, parts.normalized()],
    );
  }
}

enum _Problem {
  missingLeadingZero('no leading zero'),
  redundantLeadingZero('a redundant leading zero'),
  redundantTrailingZero('a redundant trailing zero');

  const _Problem(this.description);

  final String description;
}
