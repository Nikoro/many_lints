import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Fix that removes the duplicate cascade section.
class AvoidDuplicateCascadesFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidDuplicateCascades',
    DartFixKindPriority.standard,
    'Remove duplicate cascade section',
  );

  AvoidDuplicateCascadesFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final section = node;
    if (section is! Expression) return;

    final cascade = section.parent;
    if (cascade is! CascadeExpression) return;

    final sections = cascade.cascadeSections;
    final sectionIndex = sections.indexOf(section);
    if (sectionIndex < 0) return;

    final content = unitResult.content;

    // Determine the range to delete: from the end of the previous section
    // (or cascade target) to the end of this section, to cleanly remove
    // including any preceding whitespace/newlines.
    final int deleteStart;
    if (sectionIndex > 0) {
      deleteStart = sections[sectionIndex - 1].end;
    } else {
      deleteStart = cascade.target.end;
    }
    var deleteEnd = section.end;

    // If this is the last section and there's a trailing semicolon right
    // after, don't eat into it. But if there's whitespace between this
    // section and the next, consume it.
    if (sectionIndex < sections.length - 1) {
      // Not the last section — just delete up to section end
      deleteEnd = section.end;
    } else {
      // Last section — trim trailing whitespace up to semicolon
      while (deleteEnd < content.length &&
          (content[deleteEnd] == ' ' || content[deleteEnd] == '\t')) {
        deleteEnd++;
      }
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(SourceRange(deleteStart, deleteEnd - deleteStart));
    });
  }
}
