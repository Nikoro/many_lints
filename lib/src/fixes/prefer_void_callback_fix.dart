import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that replaces `void Function()` with `VoidCallback`.
class PreferVoidCallbackFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferVoidCallback',
    DartFixKindPriority.standard,
    "Replace with 'VoidCallback'",
  );

  PreferVoidCallbackFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! GenericFunctionType) return;

    final isNullable = targetNode.question != null;
    final replacement = isNullable ? 'VoidCallback?' : 'VoidCallback';

    await builder.addDartFileEdit(file, (builder) {
      builder.importLibrary(Uri.parse('dart:ui'));
      builder.addSimpleReplacement(range.node(targetNode), replacement);
    });
  }
}
