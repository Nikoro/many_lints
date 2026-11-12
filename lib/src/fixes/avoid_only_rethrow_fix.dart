import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class AvoidOnlyRethrowFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidOnlyRethrow',
    DartFixKindPriority.standard,
    'Remove redundant catch clause',
  );

  AvoidOnlyRethrowFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! CatchClause) return;

    final tryStatement = targetNode.parent;
    if (tryStatement is! TryStatement) return;

    final isOnlyCatch = tryStatement.catchClauses.length == 1;
    final hasFinally = tryStatement.finallyBlock != null;

    if (isOnlyCatch && !hasFinally) {
      final bodySource = tryStatement.body.statements
          .map((s) => s.toSource())
          .join('\n');

      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.node(tryStatement), bodySource);
      });
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(range.node(targetNode));
    });
  }
}
