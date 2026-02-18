import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that moves the `super` lifecycle call to the correct position.
class ProperSuperCallsFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.properSuperCalls',
    DartFixKindPriority.standard,
    'Move super call to the correct position',
  );

  ProperSuperCallsFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! MethodInvocation) return;
    if (targetNode.target is! SuperExpression) return;

    final statement = targetNode.parent;
    if (statement is! ExpressionStatement) return;

    final block = statement.parent;
    if (block is! Block) return;

    final statements = block.statements;
    if (statements.length < 2) return;

    final methodDecl = block.parent;
    BlockFunctionBody? body;
    String? methodName;
    if (methodDecl is BlockFunctionBody) {
      body = methodDecl;
      final decl = methodDecl.parent;
      if (decl is MethodDeclaration) {
        methodName = decl.name.lexeme;
      }
    }
    if (body == null || methodName == null) return;

    final shouldBeFirst = _superFirstMethods.contains(methodName);

    final superSource = statement.toSource();

    await builder.addDartFileEdit(file, (builder) {
      // Delete the super call from its current position (including newline)
      final deleteStart = statement.offset;
      var deleteEnd = statement.end;

      // Consume trailing whitespace/newline
      final content = unitResult.content;
      while (deleteEnd < content.length &&
          (content[deleteEnd] == ' ' ||
              content[deleteEnd] == '\t' ||
              content[deleteEnd] == '\n' ||
              content[deleteEnd] == '\r')) {
        deleteEnd++;
        if (content[deleteEnd - 1] == '\n') break;
      }

      // Also consume leading whitespace on the same line
      var adjustedStart = deleteStart;
      while (adjustedStart > 0 &&
          (content[adjustedStart - 1] == ' ' ||
              content[adjustedStart - 1] == '\t')) {
        adjustedStart--;
      }

      builder.addDeletion(range.startOffsetEndOffset(adjustedStart, deleteEnd));

      if (shouldBeFirst) {
        // Insert at beginning of block (after opening brace)
        final firstStatement = statements.first;
        // Get indentation from first statement
        final indent = _getIndentation(content, firstStatement.offset);
        builder.addSimpleInsertion(
          firstStatement.offset,
          '$superSource\n$indent',
        );
      } else {
        // Insert at end of block (before closing brace)
        final lastStatement = statements.last;
        final indent = _getIndentation(content, lastStatement.offset);
        builder.addSimpleInsertion(lastStatement.end, '\n$indent$superSource');
      }
    });
  }

  static const _superFirstMethods = {
    'initState',
    'didUpdateWidget',
    'activate',
    'didChangeDependencies',
    'reassemble',
  };

  /// Extracts the leading whitespace before an offset.
  static String _getIndentation(String content, int offset) {
    var start = offset;
    while (start > 0 &&
        (content[start - 1] == ' ' || content[start - 1] == '\t')) {
      start--;
    }
    return content.substring(start, offset);
  }
}
