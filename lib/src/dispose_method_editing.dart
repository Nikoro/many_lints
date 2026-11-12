import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';

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
        builder.addSimpleInsertion(
          superDisposeStmt.offset,
          '    $statementSource;\n',
        );
      } else {
        builder.addSimpleInsertion(
          block.rightBracket.offset,
          '    $statementSource;\n  ',
        );
      }
    }
  } else {
    const indent = '  ';
    final disposeMethodSource =
        '\n'
        '\n'
        '$indent@override\n'
        '${indent}void dispose() {\n'
        '$indent$indent$statementSource;\n'
        '$indent${indent}super.dispose();\n'
        '$indent}\n';

    builder.addSimpleInsertion(
      classBody.rightBracket.offset,
      disposeMethodSource,
    );
  }
}
