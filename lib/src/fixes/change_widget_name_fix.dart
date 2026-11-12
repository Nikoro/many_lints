import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ChangeWidgetNameFix extends ResolvedCorrectionProducer {
  final String widgetName;
  final FixKind _fixKind;

  ChangeWidgetNameFix._({
    required super.context,
    required this.widgetName,
    required FixKind fixKind,
  }) : _fixKind = fixKind;

  static ChangeWidgetNameFix alignFix({
    required CorrectionProducerContext context,
  }) {
    return ChangeWidgetNameFix._(
      context: context,
      widgetName: 'Align',
      fixKind: FixKind(
        'many_lints.fix.changeWidgetToAlign',
        DartFixKindPriority.standard,
        'Replace with Align',
      ),
    );
  }

  static ChangeWidgetNameFix transformFix({
    required CorrectionProducerContext context,
  }) {
    return ChangeWidgetNameFix._(
      context: context,
      widgetName: 'Transform',
      fixKind: FixKind(
        'many_lints.fix.changeWidgetToTransform',
        DartFixKindPriority.standard,
        'Replace with Transform',
      ),
    );
  }

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // Edge case: an unnamed ConstructorName shares its range with the deeper NamedType
    final targetNode = node.thisOrAncestorOfType<ConstructorName>() ?? node;
    if (targetNode is! ConstructorName) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(targetNode), widgetName);
    });
  }
}
