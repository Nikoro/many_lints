import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that replaces a body-wrapping `if` with an inverted early-return guard.
class PreferEarlyReturnFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferEarlyReturn',
    DartFixKindPriority.standard,
    'Invert the condition and return early',
  );

  PreferEarlyReturnFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final statement = node.thisOrAncestorOfType<IfStatement>();
    if (statement == null) return;
    if (statement.elseStatement != null || statement.caseClause != null) return;

    final thenBlock = statement.thenStatement;
    if (thenBlock is! Block) return;

    final wrapped = thenBlock.statements;
    if (wrapped.isEmpty) return;

    // The wrapped statements move one level out, so their source is taken as a
    // whole range — spanning any blank lines and comments between them — and
    // de-indented in one step. `indentSourceLeftRight` preserves the relative
    // indentation inside a multi-line statement, which re-indenting each
    // statement separately would flatten.
    final bodyRange = range.startEnd(wrapped.first, wrapped.last);
    final body = utils.indentSourceLeftRight(
      '${utils.getRangeText(bodyRange)}${utils.endOfLine}',
    );

    // `invertCondition` is the analyzer's own inversion, so `a && b` becomes
    // `a || !b` rather than `!(a && b)`.
    final guard = 'if (${utils.invertCondition(statement.expression)}) return;';

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.node(statement),
        '$guard'
        '${utils.endOfLine}'
        '${utils.endOfLine}'
        '${utils.getLinePrefix(statement.offset)}'
        '${body.trimRight()}',
      );
    });
  }
}
