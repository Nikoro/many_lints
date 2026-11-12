import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AvoidCommentedOutCodeFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidCommentedOutCode',
    DartFixKindPriority.standard,
    'Remove commented-out code',
  );

  AvoidCommentedOutCodeFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final offset = diagnosticOffset;
    final length = diagnosticLength;
    if (offset == null || length == null) return;

    final content = unitResult.content;
    final end = offset + length;

    var deleteStart = offset;
    while (deleteStart > 0 && content[deleteStart - 1] != '\n') {
      deleteStart--;
    }

    var deleteEnd = end;
    while (deleteEnd < content.length && content[deleteEnd] != '\n') {
      deleteEnd++;
    }
    if (deleteEnd < content.length && content[deleteEnd] == '\n') {
      deleteEnd++;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(SourceRange(deleteStart, deleteEnd - deleteStart));
    });
  }
}
