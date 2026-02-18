import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that replaces a duplicated expression with the existing variable name.
class UseExistingVariableFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.useExistingVariable',
    DartFixKindPriority.standard,
    'Replace with existing variable',
  );

  UseExistingVariableFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! Expression) return;

    final variableName = _findMatchingVariable(targetNode);
    if (variableName == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(targetNode), variableName);
    });
  }

  /// Walks up to the enclosing block and finds the final/const variable
  /// whose initializer matches the target expression's source.
  static String? _findMatchingVariable(Expression expression) {
    final expressionSource = expression.toSource();

    // Walk up to find the enclosing Block
    AstNode? current = expression.parent;
    while (current != null && current is! Block) {
      current = current.parent;
    }
    if (current is! Block) return null;

    final targetOffset = expression.offset;

    for (final statement in current.statements) {
      // Only consider statements before the target expression
      if (statement.offset >= targetOffset) break;

      if (statement is! VariableDeclarationStatement) continue;
      final isFinalOrConst =
          statement.variables.isFinal || statement.variables.isConst;
      if (!isFinalOrConst) continue;

      for (final variable in statement.variables.variables) {
        final initializer = variable.initializer;
        if (initializer == null) continue;
        if (initializer.toSource() == expressionSource) {
          return variable.name.lexeme;
        }
      }
    }

    return null;
  }
}
