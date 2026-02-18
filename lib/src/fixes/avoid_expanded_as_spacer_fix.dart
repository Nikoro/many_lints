import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import 'package:many_lints/src/ast_node_analysis.dart';

/// Fix that replaces `Expanded(child: SizedBox())` with `Spacer()`.
class AvoidExpandedAsSpacerFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidExpandedAsSpacer',
    DartFixKindPriority.standard,
    'Replace with Spacer',
  );

  AvoidExpandedAsSpacerFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;

    final NodeList<Expression> arguments;
    final String constPrefix;

    if (targetNode is InstanceCreationExpression) {
      arguments = targetNode.argumentList.arguments;
      constPrefix = targetNode.keyword?.lexeme == 'const' ? 'const ' : '';
    } else if (targetNode is MethodInvocation) {
      arguments = targetNode.argumentList.arguments;
      constPrefix = '';
    } else {
      return;
    }

    // Check for flex argument
    final flexArg = arguments.whereType<NamedExpression>().firstWhereOrNull(
      (e) => e.name.label.name == 'flex',
    );

    // Check for key argument
    final keyArg = arguments.whereType<NamedExpression>().firstWhereOrNull(
      (e) => e.name.label.name == 'key',
    );

    // Build replacement
    final buffer = StringBuffer();
    buffer.write('${constPrefix}Spacer(');

    final params = <String>[];
    if (keyArg != null) {
      params.add(keyArg.toSource());
    }
    if (flexArg != null) {
      params.add(flexArg.toSource());
    }

    buffer.write(params.join(', '));
    buffer.write(')');

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(targetNode), buffer.toString());
    });
  }
}
