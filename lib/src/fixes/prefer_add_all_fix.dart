import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

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
    // Edge case: a run of `add` calls is reported at its second call, not at a loop
    final forStatement = node.thisOrAncestorOfType<ForStatement>();
    if (forStatement != null) {
      await _fixLoop(builder, forStatement);
      return;
    }

    await _fixConsecutiveAdds(builder);
  }

  Future<void> _fixLoop(
    ChangeBuilder builder,
    ForStatement forStatement,
  ) async {
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

  Future<void> _fixConsecutiveAdds(ChangeBuilder builder) async {
    final reported = node.thisOrAncestorOfType<MethodInvocation>();
    if (reported == null) return;

    final statement = reported.thisOrAncestorOfType<ExpressionStatement>();
    if (statement == null) return;

    final block = statement.thisOrAncestorOfType<Block>();
    if (block == null) return;

    final receiver = _addReceiver(statement);
    if (receiver == null) return;

    final index = block.statements.indexOf(statement);
    if (index < 0) return;

    var start = index;
    while (start > 0 && _addReceiver(block.statements[start - 1]) == receiver) {
      start--;
    }

    var end = index;
    while (end + 1 < block.statements.length &&
        _addReceiver(block.statements[end + 1]) == receiver) {
      end++;
    }

    if (end == start) return;

    final values = <String>[];
    for (var i = start; i <= end; i++) {
      final call = _addInvocation(block.statements[i]);
      if (call == null) return;
      values.add(call.argumentList.arguments.first.toSource());
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.startEnd(block.statements[start], block.statements[end]),
        '$receiver.addAll([${values.join(', ')}]);',
      );
    });
  }

  String? _addReceiver(Statement statement) =>
      _addInvocation(statement)?.realTarget?.toSource();

  MethodInvocation? _addInvocation(Statement statement) {
    if (statement is! ExpressionStatement) return null;

    final invocation = statement.expression;
    if (invocation is! MethodInvocation) return null;
    if (invocation.methodName.name != 'add') return null;
    if (invocation.argumentList.arguments.length != 1) return null;
    if (invocation.realTarget == null) return null;

    return invocation;
  }
}
