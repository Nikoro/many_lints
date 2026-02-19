import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

import '../ast_node_analysis.dart';

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

    // Find existing dispose method
    final disposeMethod = body.members
        .whereType<MethodDeclaration>()
        .where((m) => m.name.lexeme == 'dispose')
        .firstOrNull;

    await builder.addDartFileEdit(file, (builder) {
      if (disposeMethod != null) {
        // Insert removeListener before super.dispose()
        final disposeBody = disposeMethod.body;
        if (disposeBody is BlockFunctionBody) {
          final block = disposeBody.block;
          final superDisposeStmt = _findSuperDispose(block);

          if (superDisposeStmt != null) {
            // Insert before super.dispose()
            builder.addSimpleInsertion(
              superDisposeStmt.offset,
              '    $removeCall;\n',
            );
          } else {
            // Insert at end of dispose body (before closing brace)
            builder.addSimpleInsertion(
              block.rightBracket.offset,
              '    $removeCall;\n  ',
            );
          }
        }
      } else {
        // Create a new dispose method
        final indent = '  ';
        final disposeMethodSource =
            '\n'
            '\n'
            '$indent@override\n'
            '${indent}void dispose() {\n'
            '$indent$indent$removeCall;\n'
            '$indent${indent}super.dispose();\n'
            '$indent}\n';

        // Insert at end of class body (before closing brace)
        builder.addSimpleInsertion(
          body.rightBracket.offset,
          disposeMethodSource,
        );
      }
    });
  }

  static Statement? _findSuperDispose(Block block) {
    for (final statement in block.statements) {
      if (statement is ExpressionStatement) {
        final expr = statement.expression;
        if (expr is MethodInvocation &&
            expr.methodName.name == 'dispose' &&
            expr.target is SuperExpression) {
          return statement;
        }
      }
    }
    return null;
  }
}
