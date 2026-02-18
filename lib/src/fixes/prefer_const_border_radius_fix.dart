import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that replaces `BorderRadius.circular(r)` with
/// `BorderRadius.all(Radius.circular(r))`.
class PreferConstBorderRadiusFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferConstBorderRadius',
    DartFixKindPriority.standard,
    'Replace with BorderRadius.all(Radius.circular(...))',
  );

  PreferConstBorderRadiusFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;

    final String radiusArg;
    if (targetNode is InstanceCreationExpression) {
      final args = targetNode.argumentList.arguments;
      if (args.isEmpty) return;
      radiusArg = args.first.toSource();
    } else if (targetNode is MethodInvocation) {
      final args = targetNode.argumentList.arguments;
      if (args.isEmpty) return;
      radiusArg = args.first.toSource();
    } else {
      return;
    }

    final replacement = 'BorderRadius.all(Radius.circular($radiusArg))';

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(targetNode), replacement);
    });
  }
}
