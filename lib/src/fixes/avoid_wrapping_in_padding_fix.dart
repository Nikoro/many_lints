import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../ast_node_analysis.dart';

class AvoidWrappingInPaddingFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidWrappingInPadding',
    DartFixKindPriority.standard,
    "Move padding to the child widget's padding parameter",
  );

  AvoidWrappingInPaddingFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final call = resolveWidgetCall(node);
    if (call == null) return;
    final paddingWidget = call.node;
    final paddingArgList = call.argumentList;

    final paddingArg = paddingArgList.arguments
        .whereType<NamedArgument>()
        .firstWhereOrNull((e) => e.name.lexeme == 'padding');
    if (paddingArg == null) return;

    final childArg = paddingArgList.arguments
        .whereType<NamedArgument>()
        .firstWhereOrNull((e) => e.name.lexeme == 'child');
    if (childArg == null) return;

    final childExpr = childArg.argumentExpression;

    final (childArgList, childPrefix) = switch (childExpr) {
      InstanceCreationExpression() => (
        childExpr.argumentList,
        '${childExpr.keyword != null ? '${childExpr.keyword!.lexeme} ' : ''}${childExpr.constructorName.toSource()}',
      ),
      MethodInvocation() => (childExpr.argumentList, childExpr.methodName.name),
      _ => (null, null),
    };
    if (childArgList == null || childPrefix == null) return;

    final paddingValueSource = paddingArg.argumentExpression.toSource();

    final keyArg = paddingArgList.arguments
        .whereType<NamedArgument>()
        .firstWhereOrNull((e) => e.name.lexeme == 'key');

    final existingArgs = childArgList.arguments
        .map((a) => a.toSource())
        .toList();

    if (keyArg != null) {
      final childHasKey = childArgList.arguments.whereType<NamedArgument>().any(
        (e) => e.name.lexeme == 'key',
      );
      if (!childHasKey) {
        existingArgs.insert(0, keyArg.toSource());
      }
    }

    existingArgs.add('padding: $paddingValueSource');

    final newSource = '$childPrefix(${existingArgs.join(', ')})';

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(paddingWidget), newSource);
    });
  }
}
