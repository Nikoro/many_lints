import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

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
    final targetNode = node.thisOrAncestorOfType<ClassDeclaration>();
    if (targetNode == null) return;

    final hasAbstract = targetNode.abstractKeyword != null;
    final hasFinal = targetNode.finalKeyword != null;

    // Edge case: `abstract final` turns a tolerated private no-op constructor into dead code
    final body = targetNode.body;
    final redundantConstructor = body is BlockClassBody
        ? body.members.whereType<ConstructorDeclaration>().firstOrNull
        : null;

    await builder.addDartFileEdit(file, (builder) {
      if (redundantConstructor != null) {
        builder.addDeletion(_lineRangeOf(redundantConstructor));
      }

      if (!hasAbstract && !hasFinal) {
        builder.addSimpleInsertion(
          targetNode.classKeyword.offset,
          'abstract final ',
        );
      } else if (hasAbstract && !hasFinal) {
        builder.addSimpleInsertion(targetNode.classKeyword.offset, 'final ');
      } else if (!hasAbstract && hasFinal) {
        builder.addSimpleInsertion(
          targetNode.finalKeyword!.offset,
          'abstract ',
        );
      }
    });
  }

  SourceRange _lineRangeOf(AstNode node) {
    final content = unitResult.content;

    var start = node.offset;
    while (start > 0 && content[start - 1] != '\n') {
      start--;
    }

    var end = node.end;
    while (end < content.length && content[end] != '\n') {
      end++;
    }
    if (end < content.length) end++;

    // Edge case: take the trailing blank line, since the line before holds the opening brace
    var afterBlank = end;
    while (afterBlank < content.length && content[afterBlank] != '\n') {
      if (content[afterBlank] != ' ' && content[afterBlank] != '\t') {
        return SourceRange(start, end - start);
      }
      afterBlank++;
    }
    if (afterBlank < content.length) afterBlank++;

    return SourceRange(start, afterBlank - start);
  }
}
