import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
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
    // The rule reports at the class-name token, so the covering node is a
    // name-part wrapper rather than the declaration itself.
    final targetNode = node.thisOrAncestorOfType<ClassDeclaration>();
    if (targetNode == null) return;

    final hasAbstract = targetNode.abstractKeyword != null;
    final hasFinal = targetNode.finalKeyword != null;

    // `abstract final` subsumes a private no-op constructor, so the rule
    // tolerates one — remove it here rather than leaving dead code behind.
    final body = targetNode.body;
    final redundantConstructor = body is BlockClassBody
        ? body.members.whereType<ConstructorDeclaration>().firstOrNull
        : null;

    await builder.addDartFileEdit(file, (builder) {
      if (redundantConstructor != null) {
        builder.addDeletion(_lineRangeOf(redundantConstructor));
      }

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

  /// The range covering [node]'s own lines, plus the blank line that usually
  /// follows a leading constructor.
  ///
  /// Unlike the deletion in `avoid_unnecessary_overrides_fix`, this never
  /// consumes the *preceding* blank line: the constructor being removed is
  /// typically the first member, so the line before it is the one holding the
  /// class's opening brace.
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

    // Consume one trailing blank line so removing a leading constructor does
    // not leave the class body starting with an empty line.
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
