import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Fix that removes an unnecessary method override from a State class.
class AvoidUnnecessaryOverridesInStateFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidUnnecessaryOverridesInState',
    DartFixKindPriority.standard,
    'Remove unnecessary override',
  );

  AvoidUnnecessaryOverridesInStateFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! MethodDeclaration) return;

    final content = unitResult.content;

    // Include the @override annotation if present
    final startOffset = targetNode.metadata.isNotEmpty
        ? targetNode.metadata.first.offset
        : targetNode.offset;

    // Extend to line boundaries
    var deleteStart = startOffset;
    while (deleteStart > 0 && content[deleteStart - 1] != '\n') {
      deleteStart--;
    }

    var deleteEnd = targetNode.end;
    while (deleteEnd < content.length && content[deleteEnd] != '\n') {
      deleteEnd++;
    }
    if (deleteEnd < content.length && content[deleteEnd] == '\n') {
      deleteEnd++;
    }

    // Also consume a preceding blank line if present
    if (deleteStart > 0 && content[deleteStart - 1] == '\n') {
      deleteStart--;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(SourceRange(deleteStart, deleteEnd - deleteStart));
    });
  }
}
