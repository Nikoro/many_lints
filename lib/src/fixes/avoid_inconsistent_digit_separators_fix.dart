import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:many_lints/src/digit_separator_grouping.dart';
import 'package:many_lints/src/rule_config.dart';

/// Fix that regroups a numeric literal's digits at a regular interval.
class AvoidInconsistentDigitSeparatorsFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidInconsistentDigitSeparators',
    DartFixKindPriority.standard,
    'Regroup the digit separators',
  );

  AvoidInconsistentDigitSeparatorsFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossFiles;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final literal = node.thisOrAncestorOfType<Literal>();
    final lexeme = switch (literal) {
      IntegerLiteral(:final literal) => literal.lexeme,
      DoubleLiteral(:final literal) => literal.lexeme,
      _ => null,
    };
    if (literal == null || lexeme == null) return;

    final grouping = DigitSeparatorGrouping.of(lexeme);
    if (grouping == null) return;

    // The fix must regroup to the size the rule asked for, so it reads the
    // same options the rule did rather than assuming the defaults.
    final config = _configFor(grouping);
    final regrouped = grouping.regrouped(config);
    if (regrouped == lexeme) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(literal), regrouped);
    });
  }

  int _configFor(DigitSeparatorGrouping grouping) {
    final resolved = ResolvedRuleConfig.forPath(
      packageRoot: unitResult.session.analysisContext.contextRoot.root,
      path: unitResult.path,
      ruleName: 'avoid_inconsistent_digit_separators',
    );

    return grouping.isHexadecimal
        ? resolved.config.intOption('hex_group_size', defaultValue: 4)
        : resolved.config.intOption('group_size', defaultValue: 3);
  }
}
