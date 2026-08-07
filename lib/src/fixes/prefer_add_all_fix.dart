import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that replaces an add-only loop with an `addAll` call.
class PreferAddAllFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferAddAll',
    DartFixKindPriority.standard,
    "Replace with 'addAll'",
  );

  PreferAddAllFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final forStatement = node.thisOrAncestorOfType<ForStatement>();
    if (forStatement == null) return;

    final parts = forStatement.forLoopParts;
    if (parts is! ForEachPartsWithDeclaration) return;

    final statement = switch (forStatement.body) {
      Block(:final statements) when statements.length == 1 => statements.first,
      final ExpressionStatement body => body,
      _ => null,
    };
    if (statement is! ExpressionStatement) return;

    final invocation = statement.expression;
    if (invocation is! MethodInvocation) return;

    final target = invocation.realTarget;
    if (target == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.node(forStatement),
        '${target.toSource()}.addAll(${parts.iterable.toSource()});',
      );
    });
  }
}
