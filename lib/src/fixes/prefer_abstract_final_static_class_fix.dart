import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Fix that adds `abstract final` modifiers to a static-only class.
class PreferAbstractFinalStaticClassFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferAbstractFinalStaticClass',
    DartFixKindPriority.standard,
    "Add 'abstract final' modifiers",
  );

  PreferAbstractFinalStaticClassFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! ClassDeclaration) return;

    final hasAbstract = targetNode.abstractKeyword != null;
    final hasFinal = targetNode.finalKeyword != null;

    await builder.addDartFileEdit(file, (builder) {
      if (!hasAbstract && !hasFinal) {
        // Insert "abstract final " before the "class" keyword
        builder.addSimpleInsertion(
          targetNode.classKeyword.offset,
          'abstract final ',
        );
      } else if (hasAbstract && !hasFinal) {
        // Insert "final " before the "class" keyword
        builder.addSimpleInsertion(targetNode.classKeyword.offset, 'final ');
      } else if (!hasAbstract && hasFinal) {
        // Insert "abstract " before the "final" keyword
        builder.addSimpleInsertion(
          targetNode.finalKeyword!.offset,
          'abstract ',
        );
      }
    });
  }
}
