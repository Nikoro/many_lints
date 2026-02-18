import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that replaces `Border.all(...)` with `Border.fromBorderSide(BorderSide(...))`.
class AvoidBorderAllFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidBorderAll',
    DartFixKindPriority.standard,
    'Replace with Border.fromBorderSide(BorderSide(...))',
  );

  AvoidBorderAllFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;

    final ArgumentList argumentList;
    if (targetNode is InstanceCreationExpression) {
      argumentList = targetNode.argumentList;
    } else if (targetNode is MethodInvocation) {
      argumentList = targetNode.argumentList;
    } else {
      return;
    }

    final args = argumentList.arguments;
    final argsSource = args.isEmpty
        ? ''
        : args.map((a) => a.toSource()).join(', ');

    final replacement = 'Border.fromBorderSide(BorderSide($argsSource))';

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(targetNode), replacement);
    });
  }
}
