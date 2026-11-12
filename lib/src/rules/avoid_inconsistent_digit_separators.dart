import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../digit_separator_grouping.dart';
import '../many_lints_rule.dart';

class AvoidInconsistentDigitSeparators extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_inconsistent_digit_separators',
    'The digits of this literal are grouped irregularly ({0}).',
    correctionMessage: 'Group them as {1}.',
  );

  AvoidInconsistentDigitSeparators()
    : super(
        name: 'avoid_inconsistent_digit_separators',
        description:
            'Warns when digit separators split a numeric literal into '
            'irregularly sized groups.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addIntegerLiteral(this, visitor);
    registry.addDoubleLiteral(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidInconsistentDigitSeparators rule;

  _Visitor(this.rule);

  @override
  void visitIntegerLiteral(IntegerLiteral node) =>
      _check(node, node.literal.lexeme);

  @override
  void visitDoubleLiteral(DoubleLiteral node) =>
      _check(node, node.literal.lexeme);

  void _check(Literal node, String lexeme) {
    if (!lexeme.contains('_')) return;

    final grouping = DigitSeparatorGrouping.of(lexeme);
    if (grouping == null) return;

    final expected = grouping.isHexadecimal
        ? rule.config.intOption('hex_group_size', defaultValue: 4)
        : rule.config.intOption('group_size', defaultValue: 3);

    if (grouping.isConsistentWith(expected)) return;

    rule.reportAtNode(
      node,
      arguments: [grouping.describeGroups(), grouping.regrouped(expected)],
    );
  }
}
