import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class AvoidThrowInCatchBlockFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidThrowInCatchBlock',
    DartFixKindPriority.standard,
    'Use Error.throwWithStackTrace()',
  );

  AvoidThrowInCatchBlockFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! ThrowExpression) return;

    final catchClause = _findCatchClause(targetNode);
    if (catchClause == null) return;

    final thrownExpr = targetNode.expression.toSource();
    final stackTraceName = catchClause.stackTraceParameter?.name.lexeme;

    if (stackTraceName != null) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(
          range.node(targetNode),
          'Error.throwWithStackTrace($thrownExpr, $stackTraceName)',
        );
      });
    } else {
      const stackParam = 'stackTrace';

      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(
          range.node(targetNode),
          'Error.throwWithStackTrace($thrownExpr, $stackParam)',
        );

        _addStackTraceParameter(builder, catchClause, stackParam);
      });
    }
  }

  void _addStackTraceParameter(
    DartFileEditBuilder builder,
    CatchClause catchClause,
    String stackParam,
  ) {
    final exceptionParam = catchClause.exceptionParameter;

    if (exceptionParam != null) {
      builder.addSimpleInsertion(exceptionParam.end, ', $stackParam');
    } else if (catchClause.catchKeyword != null) {
      final catchKeyword = catchClause.catchKeyword!;
      builder.addSimpleInsertion(catchKeyword.end, ' (_, $stackParam)');
    } else {
      final body = catchClause.body;
      builder.addSimpleInsertion(
        body.leftBracket.offset,
        'catch (_, $stackParam) ',
      );
    }
  }

  static CatchClause? _findCatchClause(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is CatchClause) return current;
      if (current is FunctionExpression || current is FunctionDeclaration) {
        return null;
      }
      current = current.parent;
    }
    return null;
  }
}
