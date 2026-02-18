import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import 'package:many_lints/src/ast_node_analysis.dart';

/// Fix that removes the unnecessary GestureDetector and replaces it with its
/// child widget.
class AvoidUnnecessaryGestureDetectorFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidUnnecessaryGestureDetector',
    DartFixKindPriority.standard,
    'Remove unnecessary GestureDetector',
  );

  AvoidUnnecessaryGestureDetectorFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;

    // The reported node can be ConstructorName or SimpleIdentifier
    final Expression gestureDetectorExpr;
    final NodeList<Expression> arguments;

    if (targetNode is ConstructorName &&
        targetNode.parent is InstanceCreationExpression) {
      final ice = targetNode.parent! as InstanceCreationExpression;
      gestureDetectorExpr = ice;
      arguments = ice.argumentList.arguments;
    } else if (targetNode is SimpleIdentifier &&
        targetNode.parent is MethodInvocation) {
      final mi = targetNode.parent! as MethodInvocation;
      gestureDetectorExpr = mi;
      arguments = mi.argumentList.arguments;
    } else {
      return;
    }

    // Find the child argument
    final childArg = arguments.whereType<NamedExpression>().firstWhereOrNull(
      (e) => e.name.label.name == 'child',
    );

    if (childArg == null) return;

    final childSource = childArg.expression.toSource();

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.node(gestureDetectorExpr),
        childSource,
      );
    });
  }
}
