import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import 'package:many_lints/src/utils/helpers.dart';

/// Fix that replaces Align(alignment: center) with Center.
class PreferCenterOverAlignFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferCenterOverAlign',
    DartFixKindPriority.standard,
    'Replace with Center',
  );

  PreferCenterOverAlignFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! ConstructorName) return;

    final instanceCreation = targetNode.parent;
    if (instanceCreation is! InstanceCreationExpression) return;

    // Find alignment argument to remove
    final alignmentArgument = instanceCreation.argumentList.arguments
        .whereType<NamedExpression>()
        .firstWhereOrNull((e) => e.name.label.name == 'alignment');

    await builder.addDartFileEdit(file, (builder) {
      // Replace Align with Center
      builder.addSimpleReplacement(range.node(targetNode), 'Center');

      // Remove alignment argument if present
      if (alignmentArgument != null) {
        builder.addDeletion(
          range.nodeInList(
            instanceCreation.argumentList.arguments,
            alignmentArgument,
          ),
        );
      }
    });
  }
}
