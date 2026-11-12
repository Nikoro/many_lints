import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../ast_node_analysis.dart';

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
    // Edge case: an unnamed ConstructorName shares its range with the deeper NamedType
    final targetNode = node.thisOrAncestorOfType<ConstructorName>() ?? node;
    if (targetNode is! ConstructorName) return;

    final instanceCreation = targetNode.parent;
    if (instanceCreation is! InstanceCreationExpression) return;

    final marginArgument = instanceCreation.argumentList.arguments
        .whereType<NamedArgument>()
        .firstWhereOrNull((e) => e.name.lexeme == 'margin');

    final paddingArgument = instanceCreation.argumentList.arguments
        .whereType<NamedArgument>()
        .firstWhereOrNull((e) => e.name.lexeme == 'padding');

    if (marginArgument == null && paddingArgument == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(targetNode), 'Padding');
      if (marginArgument != null) {
        builder.addSimpleReplacement(
          range.token(marginArgument.name),
          'padding',
        );
      }
    });
  }
}
