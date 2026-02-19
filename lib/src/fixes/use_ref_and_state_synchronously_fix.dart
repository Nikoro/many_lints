import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Fix that adds `if (!ref.mounted) return;` before ref/state access after
/// an async gap.
class UseRefAndStateSynchronouslyFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.useRefAndStateSynchronously',
    DartFixKindPriority.standard,
    "Add 'if (!ref.mounted) return;' guard",
  );

  UseRefAndStateSynchronouslyFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // Find the enclosing statement to insert the guard before it
    final statement = _findEnclosingStatement(node);
    if (statement == null) return;

    // Determine indentation from the statement
    final content = unitResult.content;
    var lineStart = statement.offset;
    while (lineStart > 0 && content[lineStart - 1] != '\n') {
      lineStart--;
    }
    final indent = content.substring(lineStart, statement.offset);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(
        statement.offset,
        'if (!ref.mounted) return;\n$indent',
      );
    });
  }

  static Statement? _findEnclosingStatement(AstNode node) {
    AstNode? current = node;
    while (current != null) {
      if (current is Statement) return current;
      current = current.parent;
    }
    return null;
  }
}
