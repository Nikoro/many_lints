import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

import '../ast_node_analysis.dart';
import '../dispose_method_editing.dart';

/// Fix that adds a matching removeListener() call in dispose().
class AlwaysRemoveListenerFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.alwaysRemoveListener',
    DartFixKindPriority.standard,
    'Add removeListener() in dispose()',
  );

  AlwaysRemoveListenerFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! MethodInvocation) return;

    // Build the removeListener call source
    final target = targetNode.realTarget;
    final targetSource = target?.toSource() ?? '';
    final args = targetNode.argumentList.arguments;
    if (args.isEmpty) return;
    final listenerSource = args.first.toSource();

    final removeCall = targetSource.isEmpty
        ? 'removeListener($listenerSource)'
        : '$targetSource.removeListener($listenerSource)';

    // Find the enclosing class declaration
    final classDecl = enclosingClassDeclaration(targetNode);
    if (classDecl == null) return;

    final body = classDecl.body;
    if (body is! BlockClassBody) return;

    await builder.addDartFileEdit(file, (builder) {
      insertIntoDisposeMethod(builder, body, removeCall);
    });
  }
}
