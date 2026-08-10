import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';

/// Returns the `super.dispose();` statement in [block], or `null`.
///
/// Cleanup calls must run *before* `super.dispose()`, because the superclass
/// may tear down state the call still needs. Fixes therefore locate this
/// statement to use its offset as the insertion point.
Statement? findSuperDisposeCall(Block block) {
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

/// Inserts `<statementSource>;` into [classBody]'s `dispose()` method,
/// synthesising the whole method when the class has none.
///
/// Shared by every fix whose remedy is "clean this up in `dispose()`". The
/// placement rules are identical across them — before `super.dispose()` when it
/// exists, otherwise just inside the closing brace, otherwise a fresh
/// `@override void dispose()` at the end of the class — and only the statement
/// text differs, so it is the single parameter.
///
/// Does nothing when a `dispose()` exists with a non-block body: there is no
/// statement list to insert into, and rewriting an expression body would be a
/// different edit than the one offered.
void insertIntoDisposeMethod(
  DartFileEditBuilder builder,
  BlockClassBody classBody,
  String statementSource,
) {
  final disposeMethod = classBody.members
      .whereType<MethodDeclaration>()
      .where((m) => m.name.lexeme == 'dispose')
      .firstOrNull;

  if (disposeMethod != null) {
    final disposeBody = disposeMethod.body;
    if (disposeBody is BlockFunctionBody) {
      final block = disposeBody.block;
      final superDisposeStmt = findSuperDisposeCall(block);

      if (superDisposeStmt != null) {
        // Insert before super.dispose()
        builder.addSimpleInsertion(
          superDisposeStmt.offset,
          '    $statementSource;\n',
        );
      } else {
        // Insert at end of dispose body (before closing brace)
        builder.addSimpleInsertion(
          block.rightBracket.offset,
          '    $statementSource;\n  ',
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
        '$indent$indent$statementSource;\n'
        '$indent${indent}super.dispose();\n'
        '$indent}\n';

    // Insert at end of class body (before closing brace)
    builder.addSimpleInsertion(
      classBody.rightBracket.offset,
      disposeMethodSource,
    );
  }
}
