import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that wraps the if-null expression in parentheses to clarify
/// cascade operator precedence.
class AvoidCascadeAfterIfNullFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidCascadeAfterIfNull',
    DartFixKindPriority.standard,
    'Wrap if-null expression in parentheses',
  );

  AvoidCascadeAfterIfNullFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! CascadeExpression) return;

    final binaryExpr = targetNode.target;
    if (binaryExpr is! BinaryExpression) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.node(binaryExpr),
        '(${binaryExpr.toSource()})',
      );
    });
  }
}
