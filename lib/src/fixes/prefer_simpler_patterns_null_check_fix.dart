import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class PreferSimplerPatternsNullCheckFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferSimplerPatternsNullCheck',
    DartFixKindPriority.standard,
    'Simplify null-check pattern',
  );

  PreferSimplerPatternsNullCheckFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! LogicalAndPattern) return;

    final right = targetNode.rightOperand;
    if (right is! DeclaredVariablePattern) return;

    final hasTypeAnnotation = right.type != null;

    final String replacement;
    if (hasTypeAnnotation) {
      replacement = right.toSource();
    } else {
      replacement = '${right.toSource()}?';
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(targetNode), replacement);
    });
  }
}
