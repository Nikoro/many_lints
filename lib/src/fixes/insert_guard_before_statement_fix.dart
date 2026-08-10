import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

import '../ast_node_analysis.dart';

/// Shared algorithm for the fixes that insert an early-return guard in front of
/// the statement a diagnostic was reported inside.
///
/// The "use X synchronously" family of rules all report a use of some
/// disposable object after an async gap, and every one of them is fixed the
/// same way: walk out to the enclosing statement and insert a guard on its own
/// line, indented to match. Only the guard text differs, so subclasses supply
/// [guardSource] and their own [fixKind] and the algorithm lives here once.
abstract class InsertGuardBeforeStatementFix
    extends ResolvedCorrectionProducer {
  InsertGuardBeforeStatementFix({required super.context});

  /// The guard statement to insert, without a trailing newline.
  ///
  /// For example `'if (!mounted) return;'`.
  String get guardSource;

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // Find the enclosing statement to insert the guard before it
    final statement = enclosingOfType<Statement>(node);
    if (statement == null) return;

    // Determine indentation from the statement
    final indent = indentOf(unitResult.content, statement.offset);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(statement.offset, '$guardSource\n$indent');
    });
  }
}
