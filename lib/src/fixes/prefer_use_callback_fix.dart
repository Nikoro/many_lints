import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class PreferUseCallbackFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferUseCallback',
    DartFixKindPriority.standard,
    "Replace with 'useCallback'",
  );

  PreferUseCallbackFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! MethodInvocation) return;

    final args = targetNode.argumentList.arguments;
    if (args.isEmpty) return;

    final factory = args.first;
    if (factory is! FunctionExpression) return;

    final body = factory.body;

    Expression? returnExpression;
    if (body is ExpressionFunctionBody) {
      returnExpression = body.expression;
    } else if (body is BlockFunctionBody) {
      final statements = body.block.statements;
      if (statements.length == 1 && statements.first is ReturnStatement) {
        returnExpression = (statements.first as ReturnStatement).expression;
      }
    }

    if (returnExpression == null) return;

    final callbackSource = returnExpression.toSource();

    final remainingArgs = args.length > 1
        ? ', ${args.skip(1).map((a) => a.toSource()).join(', ')}'
        : '';

    final replacement = 'useCallback($callbackSource$remainingArgs)';

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(targetNode), replacement);
    });
  }
}
