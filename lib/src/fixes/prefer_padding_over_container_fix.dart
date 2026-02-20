import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../ast_node_analysis.dart';

/// Fix that replaces Container(padding/margin: ...) with Padding(padding: ...).
class PreferPaddingOverContainerFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferPaddingOverContainer',
    DartFixKindPriority.standard,
    'Replace with Padding',
  );

  PreferPaddingOverContainerFix({required super.context});

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

    // Find margin or padding argument
    final marginArgument = instanceCreation.argumentList.arguments
        .whereType<NamedExpression>()
        .firstWhereOrNull((e) => e.name.label.name == 'margin');

    final paddingArgument = instanceCreation.argumentList.arguments
        .whereType<NamedExpression>()
        .firstWhereOrNull((e) => e.name.label.name == 'padding');

    if (marginArgument == null && paddingArgument == null) return;

    await builder.addDartFileEdit(file, (builder) {
      // Replace Container with Padding
      builder.addSimpleReplacement(range.node(targetNode), 'Padding');
      // Rename margin to padding if needed (padding is already correct)
      if (marginArgument != null) {
        builder.addSimpleReplacement(
          range.node(marginArgument.name.label),
          'padding',
        );
      }
    });
  }
}
