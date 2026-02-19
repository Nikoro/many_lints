import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

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

  static const _cleanupMethods = ['dispose', 'close', 'cancel'];

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // The diagnostic is reported at the variable name token.
    final targetNode = node;

    // Walk up to find the VariableDeclaration
    final varDecl = _findVariableDeclaration(targetNode);
    if (varDecl == null) return;

    final fieldName = varDecl.name.lexeme;
    final type = varDecl.declaredFragment?.element.type;
    if (type == null) return;

    final cleanupMethod = _findCleanupMethod(type);
    if (cleanupMethod == null) return;

    // Find the enclosing statement (VariableDeclarationStatement)
    final statement = _findEnclosingStatement(varDecl);
    if (statement == null) return;

    final onDisposeCall = 'ref.onDispose($fieldName.$cleanupMethod)';

    // Determine indentation from the variable declaration statement
    final content = unitResult.content;
    final lineStart = _findLineStart(content, statement.offset);
    final indent = content.substring(lineStart, statement.offset);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(statement.end, '\n$indent$onDisposeCall;');
    });
  }

  static VariableDeclaration? _findVariableDeclaration(AstNode node) {
    AstNode? current = node;
    while (current != null) {
      if (current is VariableDeclaration) return current;
      current = current.parent;
    }
    return null;
  }

  static Statement? _findEnclosingStatement(AstNode node) {
    AstNode? current = node;
    while (current != null) {
      if (current is Statement) return current;
      current = current.parent;
    }
    return null;
  }

  static int _findLineStart(String content, int offset) {
    var i = offset - 1;
    while (i >= 0 && content[i] != '\n') {
      i--;
    }
    return i + 1;
  }

  static String? _findCleanupMethod(DartType type) {
    if (type is! InterfaceType) return null;

    final allMethods = <String>{};
    for (final method in type.methods) {
      final name = method.name;
      if (name != null) allMethods.add(name);
    }
    for (final supertype in type.element.allSupertypes) {
      for (final method in supertype.methods) {
        final name = method.name;
        if (name != null) allMethods.add(name);
      }
    }

    for (final cleanup in _cleanupMethods) {
      if (allMethods.contains(cleanup)) return cleanup;
    }
    return null;
  }
}
