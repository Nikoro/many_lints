import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

import '../ast_node_analysis.dart';

abstract class InsertGuardBeforeStatementFix
    extends ResolvedCorrectionProducer {
  InsertGuardBeforeStatementFix({required super.context});

  String get guardSource;

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final statement = enclosingOfType<Statement>(node);
    if (statement == null) return;

    final indent = indentOf(unitResult.content, statement.offset);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(statement.offset, '$guardSource\n$indent');
    });
  }
}
