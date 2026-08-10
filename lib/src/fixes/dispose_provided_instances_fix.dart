import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

import '../ast_node_analysis.dart';
import '../disposal_utils.dart';

/// Fix that adds `ref.onDispose(instance.dispose)` after the variable
/// declaration of a disposable instance inside a Riverpod provider or
/// Notifier build().
class DisposeProvidedInstancesFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.disposeProvidedInstances',
    DartFixKindPriority.standard,
    'Add ref.onDispose() call',
  );

  DisposeProvidedInstancesFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // The diagnostic is reported at the variable name token.
    final targetNode = node;

    // Walk up to find the VariableDeclaration
    final varDecl = enclosingOfType<VariableDeclaration>(targetNode);
    if (varDecl == null) return;

    final fieldName = varDecl.name.lexeme;
    final type = varDecl.declaredFragment?.element.type;
    if (type == null) return;

    final cleanupMethod = findCleanupMethod(type);
    if (cleanupMethod == null) return;

    // Find the enclosing statement (VariableDeclarationStatement)
    final statement = enclosingOfType<Statement>(varDecl);
    if (statement == null) return;

    final onDisposeCall = 'ref.onDispose($fieldName.$cleanupMethod)';

    // Determine indentation from the variable declaration statement
    final indent = indentOf(unitResult.content, statement.offset);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(statement.end, '\n$indent$onDisposeCall;');
    });
  }
}
