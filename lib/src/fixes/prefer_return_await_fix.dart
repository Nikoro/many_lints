import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that adds `await` before a returned Future inside a try-catch block.
class PreferReturnAwaitFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferReturnAwait',
    DartFixKindPriority.standard,
    'Add await before returned expression',
  );

  PreferReturnAwaitFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! Expression) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.node(targetNode),
        'await ${targetNode.toSource()}',
      );
    });
  }
}
