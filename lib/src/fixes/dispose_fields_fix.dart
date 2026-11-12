import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

import '../ast_node_analysis.dart';
import '../dispose_method_editing.dart';
import '../disposal_utils.dart';

class DisposeFieldsFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.disposeFields',
    DartFixKindPriority.standard,
    'Add disposal call in dispose()',
  );

  DisposeFieldsFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;

    final varDecl = enclosingOfType<VariableDeclaration>(targetNode);
    if (varDecl == null) return;

    final fieldName = varDecl.name.lexeme;
    final type = varDecl.declaredFragment?.element.type;
    if (type == null) return;

    final cleanupMethod = findCleanupMethod(type);
    if (cleanupMethod == null) return;

    final disposeCall = '$fieldName.$cleanupMethod()';

    final classDecl = enclosingClassDeclaration(targetNode);
    if (classDecl == null) return;

    final body = classDecl.body;
    if (body is! BlockClassBody) return;

    await builder.addDartFileEdit(file, (builder) {
      insertIntoDisposeMethod(builder, body, disposeCall);
    });
  }
}
