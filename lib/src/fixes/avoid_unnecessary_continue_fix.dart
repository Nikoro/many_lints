import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class AvoidUnnecessaryContinueFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidUnnecessaryContinue',
    DartFixKindPriority.standard,
    'Remove unnecessary `continue`',
  );

  AvoidUnnecessaryContinueFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final statement = node.thisOrAncestorOfType<ContinueStatement>();
    if (statement == null) return;

    await builder.addDartFileEdit(file, (builder) {
      // Edge case: taking the whitespace leaves no blank line when it was the only statement
      final parent = statement.parent;
      if (parent is Block) {
        builder.addDeletion(range.nodeInList(parent.statements, statement));
      } else {
        // Edge case: a loop without braces still needs a body statement
        builder.addSimpleReplacement(range.node(statement), '{}');
      }
    });
  }
}
