import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that removes the unnecessary `setState` call and inlines its body
/// statements directly.
class AvoidUnnecessarySetstateFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidUnnecessarySetstate',
    DartFixKindPriority.standard,
    'Remove unnecessary setState call',
  );

  AvoidUnnecessarySetstateFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! SimpleIdentifier) return;

    final invocation = targetNode.parent;
    if (invocation is! MethodInvocation) return;

    // Get the callback argument
    final args = invocation.argumentList.arguments;
    if (args.isEmpty) return;

    final callback = args.first;
    if (callback is! FunctionExpression) return;

    final body = callback.body;

    // Expression body: setState(() => expr) → expr;
    if (body is ExpressionFunctionBody) {
      final exprSource = body.expression.toSource();

      // Find the ExpressionStatement that contains the MethodInvocation
      final statement = invocation.parent;
      if (statement is! ExpressionStatement) return;

      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.node(statement), '$exprSource;');
      });
      return;
    }

    // Block body: setState(() { stmts }) → stmts
    if (body is BlockFunctionBody) {
      final statements = body.block.statements;

      // Find the ExpressionStatement that contains the MethodInvocation
      final statement = invocation.parent;
      if (statement is! ExpressionStatement) return;

      if (statements.isEmpty) {
        // Empty setState — just remove the whole statement
        await builder.addDartFileEdit(file, (builder) {
          builder.addDeletion(range.node(statement));
        });
        return;
      }

      // Extract the inner statements as source
      final innerSource = statements.map((s) => s.toSource()).join('\n    ');

      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.node(statement), innerSource);
      });
    }
  }
}
