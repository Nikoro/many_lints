import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../ast_node_analysis.dart';

/// Fix that replaces `SizedBox(width: x, height: x)` with
/// `SizedBox.square(dimension: x)`.
class PreferSizedBoxSquareFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferSizedBoxSquare',
    DartFixKindPriority.standard,
    'Replace with SizedBox.square',
  );

  PreferSizedBoxSquareFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;

    // Find the enclosing creation expression
    final Expression creationExpr;
    if (targetNode is ConstructorName) {
      final parent = targetNode.parent;
      if (parent is! InstanceCreationExpression) return;
      creationExpr = parent;
    } else if (targetNode is SimpleIdentifier &&
        targetNode.parent is MethodInvocation) {
      creationExpr = targetNode.parent! as MethodInvocation;
    } else {
      return;
    }

    final ArgumentList argumentList;
    if (creationExpr is InstanceCreationExpression) {
      argumentList = creationExpr.argumentList;
    } else if (creationExpr is MethodInvocation) {
      argumentList = creationExpr.argumentList;
    } else {
      return;
    }

    final args = argumentList.arguments.whereType<NamedExpression>();

    final widthArg = args.firstWhereOrNull((a) => a.name.label.name == 'width');
    if (widthArg == null) return;

    // Build the replacement: keep all args except width/height,
    // replace them with dimension.
    final otherArgs = <String>[];
    for (final arg in argumentList.arguments) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        if (name == 'width' || name == 'height') continue;
      }
      otherArgs.add(arg.toSource());
    }

    final dimensionSource = widthArg.expression.toSource();
    final allArgs = [...otherArgs, 'dimension: $dimensionSource'];

    final constPrefix =
        creationExpr is InstanceCreationExpression &&
            creationExpr.keyword != null
        ? '${creationExpr.keyword!.lexeme} '
        : '';

    final replacement = '${constPrefix}SizedBox.square(${allArgs.join(', ')})';

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(creationExpr), replacement);
    });
  }
}
