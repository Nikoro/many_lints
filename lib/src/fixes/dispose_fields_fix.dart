import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

import '../ast_node_analysis.dart';
import '../disposal_utils.dart';

/// Fix that adds the appropriate cleanup call (dispose/close/cancel)
/// for an undisposed field in the dispose() method.
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
    // The diagnostic is reported at the variable name token.
    // The node is the SimpleIdentifier inside a VariableDeclaration.
    final targetNode = node;

    // Walk up to find the VariableDeclaration
    final varDecl = _findVariableDeclaration(targetNode);
    if (varDecl == null) return;

    final fieldName = varDecl.name.lexeme;
    final type = varDecl.declaredFragment?.element.type;
    if (type == null) return;

    final cleanupMethod = findCleanupMethod(type);
    if (cleanupMethod == null) return;

    final disposeCall = '$fieldName.$cleanupMethod()';

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
        // Insert cleanup call before super.dispose()
        final disposeBody = disposeMethod.body;
        if (disposeBody is BlockFunctionBody) {
          final block = disposeBody.block;
          final superDisposeStmt = _findSuperDispose(block);

          if (superDisposeStmt != null) {
            builder.addSimpleInsertion(
              superDisposeStmt.offset,
              '    $disposeCall;\n',
            );
          } else {
            builder.addSimpleInsertion(
              block.rightBracket.offset,
              '    $disposeCall;\n  ',
            );
          }
        }
      } else {
        // Create a new dispose method
        const indent = '  ';
        final disposeMethodSource =
            '\n'
            '\n'
            '$indent@override\n'
            '${indent}void dispose() {\n'
            '$indent$indent$disposeCall;\n'
            '$indent${indent}super.dispose();\n'
            '$indent}\n';

        builder.addSimpleInsertion(
          body.rightBracket.offset,
          disposeMethodSource,
        );
      }
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
