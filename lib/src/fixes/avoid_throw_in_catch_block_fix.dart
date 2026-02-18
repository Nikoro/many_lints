import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that replaces `throw` in a catch block with
/// `Error.throwWithStackTrace()` to preserve the original stack trace.
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
      // Stack trace parameter already exists — just replace the throw
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(
          range.node(targetNode),
          'Error.throwWithStackTrace($thrownExpr, $stackTraceName)',
        );
      });
    } else {
      // Need to add the stack trace parameter to the catch clause
      const stackParam = 'stackTrace';

      await builder.addDartFileEdit(file, (builder) {
        // Replace throw expression
        builder.addSimpleReplacement(
          range.node(targetNode),
          'Error.throwWithStackTrace($thrownExpr, $stackParam)',
        );

        // Add stack trace parameter to catch clause
        _addStackTraceParameter(builder, catchClause, stackParam);
      });
    }
  }

  void _addStackTraceParameter(
    dynamic builder,
    CatchClause catchClause,
    String stackParam,
  ) {
    final exceptionParam = catchClause.exceptionParameter;

    if (exceptionParam != null) {
      // Has exception parameter: `catch (e)` → `catch (e, stackTrace)`
      builder.addSimpleInsertion(exceptionParam.end, ', $stackParam');
    } else if (catchClause.catchKeyword != null) {
      // Has `catch` keyword but no params (shouldn't normally happen)
      // `catch` → `catch (_, stackTrace)`
      final catchKeyword = catchClause.catchKeyword!;
      builder.addSimpleInsertion(catchKeyword.end, ' (_, $stackParam)');
    } else {
      // Only `on Type` without `catch`: `on Type {` → `on Type catch (_, stackTrace) {`
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
