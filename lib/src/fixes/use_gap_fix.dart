import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import 'package:many_lints/src/utils/helpers.dart';

/// Fix that replaces SizedBox or Padding with Gap widget for spacing.
class UseGapFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.useGap',
    DartFixKindPriority.standard,
    'Replace with Gap',
  );

  UseGapFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! ConstructorName) return;

    final instanceCreation = targetNode.parent;
    if (instanceCreation is! InstanceCreationExpression) return;

    final typeName = targetNode.type.name.lexeme;

    if (typeName == 'SizedBox') {
      await _fixSizedBox(builder, instanceCreation);
    } else if (typeName == 'Padding') {
      await _fixPadding(builder, instanceCreation);
    }
  }

  Future<void> _fixSizedBox(
    ChangeBuilder builder,
    InstanceCreationExpression node,
  ) async {
    // Find the spacing value from height or width argument
    final spacingArg = node.argumentList.arguments
        .whereType<NamedExpression>()
        .firstWhereOrNull(
          (e) => e.name.label.name == 'height' || e.name.label.name == 'width',
        );

    if (spacingArg == null) return;

    final valueSource = spacingArg.expression.toSource();

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(node), 'Gap($valueSource)');
    });
  }

  Future<void> _fixPadding(
    ChangeBuilder builder,
    InstanceCreationExpression node,
  ) async {
    // Extract the padding value from EdgeInsets.only
    final paddingArg = node.argumentList.arguments
        .whereType<NamedExpression>()
        .firstWhereOrNull((e) => e.name.label.name == 'padding');

    if (paddingArg == null) return;

    final paddingExpr = paddingArg.expression;
    if (paddingExpr is! InstanceCreationExpression) return;

    // Get the single direction argument and its value
    final dirArgs = paddingExpr.argumentList.arguments
        .whereType<NamedExpression>()
        .where((e) => e.name.label.name != 'key')
        .toList();

    if (dirArgs.length != 1) return;

    final dirName = dirArgs.first.name.label.name;
    final valueSource = dirArgs.first.expression.toSource();

    // Extract the child widget
    final childArg = node.argumentList.arguments
        .whereType<NamedExpression>()
        .firstWhereOrNull((e) => e.name.label.name == 'child');

    if (childArg == null) return;

    final childSource = childArg.expression.toSource();

    // Determine if Gap goes before or after the child
    final gapBefore = dirName == 'top' || dirName == 'left' || dirName == 'start';

    final replacement = gapBefore
        ? 'Gap($valueSource), $childSource'
        : '$childSource, Gap($valueSource)';

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(node), replacement);
    });
  }
}
