import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../ast_node_analysis.dart';

/// Fix that moves opacity from Opacity wrapper to Image's opacity parameter.
class AvoidIncorrectImageOpacityFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidIncorrectImageOpacity',
    DartFixKindPriority.standard,
    "Move opacity to Image's opacity parameter",
  );

  AvoidIncorrectImageOpacityFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // The reported node can be ConstructorName or SimpleIdentifier
    final Expression opacityCreation;
    final NodeList<Expression> arguments;

    final targetNode = node;
    if (targetNode is ConstructorName &&
        targetNode.parent is InstanceCreationExpression) {
      final ice = targetNode.parent! as InstanceCreationExpression;
      opacityCreation = ice;
      arguments = ice.argumentList.arguments;
    } else if (targetNode is SimpleIdentifier &&
        targetNode.parent is MethodInvocation) {
      final mi = targetNode.parent! as MethodInvocation;
      opacityCreation = mi;
      arguments = mi.argumentList.arguments;
    } else {
      return;
    }

    // Find the opacity value
    final opacityArg = arguments.whereType<NamedExpression>().firstWhereOrNull(
      (e) => e.name.label.name == 'opacity',
    );

    // Find the child (Image widget)
    final childArg = arguments.whereType<NamedExpression>().firstWhereOrNull(
      (e) => e.name.label.name == 'child',
    );

    if (childArg == null) return;
    final imageExpr = childArg.expression;

    // Get the image's argument list
    final ArgumentList imageArgList;
    if (imageExpr is InstanceCreationExpression) {
      imageArgList = imageExpr.argumentList;
    } else if (imageExpr is MethodInvocation) {
      imageArgList = imageExpr.argumentList;
    } else {
      return;
    }

    // Check if Image already has an opacity parameter
    final hasOpacity = imageArgList.arguments.whereType<NamedExpression>().any(
      (e) => e.name.label.name == 'opacity',
    );

    if (hasOpacity) return;

    final opacityValue = opacityArg?.expression.toSource() ?? '1.0';
    final imageSource = imageExpr.toSource();

    // Build the new Image source with opacity parameter added
    final imageStart = imageExpr.offset;
    final closeParenRelative =
        imageArgList.rightParenthesis.offset - imageStart;

    final String newImageSource;
    if (imageArgList.arguments.isEmpty) {
      newImageSource =
          '${imageSource.substring(0, closeParenRelative)}opacity: AlwaysStoppedAnimation($opacityValue)${imageSource.substring(closeParenRelative)}';
    } else {
      final lastArg = imageArgList.arguments.last;
      final lastArgEndRelative = lastArg.end - imageStart;
      newImageSource =
          '${imageSource.substring(0, lastArgEndRelative)}, opacity: AlwaysStoppedAnimation($opacityValue)${imageSource.substring(lastArgEndRelative)}';
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(opacityCreation), newImageSource);
    });
  }
}
