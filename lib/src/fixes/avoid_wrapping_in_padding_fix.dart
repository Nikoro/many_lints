import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../ast_node_analysis.dart';

/// Fix that removes the wrapping Padding widget and moves the padding value
/// to the child widget's padding parameter.
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
    final targetNode = node;

    // The report node is either a ConstructorName or SimpleIdentifier
    final (paddingWidget, paddingArgList) = switch (targetNode) {
      ConstructorName(parent: InstanceCreationExpression parent) => (
        parent as Expression,
        parent.argumentList,
      ),
      SimpleIdentifier(parent: MethodInvocation parent) => (
        parent as Expression,
        parent.argumentList,
      ),
      _ => (null, null),
    };
    if (paddingWidget == null || paddingArgList == null) return;

    // Find the padding argument from the Padding widget
    final paddingArg = paddingArgList.arguments
        .whereType<NamedExpression>()
        .firstWhereOrNull((e) => e.name.label.name == 'padding');
    if (paddingArg == null) return;

    // Find the child argument
    final childArg = paddingArgList.arguments
        .whereType<NamedExpression>()
        .firstWhereOrNull((e) => e.name.label.name == 'child');
    if (childArg == null) return;

    final childExpr = childArg.expression;

    // Get child's argument list and source prefix
    final (childArgList, childPrefix) = switch (childExpr) {
      InstanceCreationExpression() => (
        childExpr.argumentList,
        '${childExpr.keyword != null ? '${childExpr.keyword!.lexeme} ' : ''}${childExpr.constructorName.toSource()}',
      ),
      MethodInvocation() => (childExpr.argumentList, childExpr.methodName.name),
      _ => (null, null),
    };
    if (childArgList == null || childPrefix == null) return;

    // Extract the padding value source
    final paddingValueSource = paddingArg.expression.toSource();

    // Find the key argument if present (from the Padding widget)
    final keyArg = paddingArgList.arguments
        .whereType<NamedExpression>()
        .firstWhereOrNull((e) => e.name.label.name == 'key');

    // Build the new argument list for the child widget
    final existingArgs = childArgList.arguments
        .map((a) => a.toSource())
        .toList();

    // Add the key from Padding if the child doesn't already have one
    if (keyArg != null) {
      final childHasKey = childArgList.arguments
          .whereType<NamedExpression>()
          .any((e) => e.name.label.name == 'key');
      if (!childHasKey) {
        existingArgs.insert(0, keyArg.toSource());
      }
    }

    // Add the padding argument
    existingArgs.add('padding: $paddingValueSource');

    final newSource = '$childPrefix(${existingArgs.join(', ')})';

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(paddingWidget), newSource);
    });
  }
}
