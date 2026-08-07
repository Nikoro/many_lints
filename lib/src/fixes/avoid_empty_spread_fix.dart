import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that removes a spread of an empty collection literal.
class AvoidEmptySpreadFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidEmptySpread',
    DartFixKindPriority.standard,
    'Remove empty spread',
  );

  AvoidEmptySpreadFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final spread = node.thisOrAncestorOfType<SpreadElement>();
    if (spread == null) return;

    // The enclosing literal owns the separating commas, so delete through
    // `nodeInList` to take the trailing comma with it.
    final elements = switch (spread.parent) {
      ListLiteral(:final elements) => elements,
      SetOrMapLiteral(:final elements) => elements,
      _ => null,
    };
    if (elements == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(range.nodeInList(elements, spread));
    });
  }
}
