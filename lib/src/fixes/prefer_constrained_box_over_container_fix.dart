import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that replaces Container(constraints: ...) with ConstrainedBox(constraints: ...).
class PreferConstrainedBoxOverContainerFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferConstrainedBoxOverContainer',
    DartFixKindPriority.standard,
    'Replace with ConstrainedBox',
  );

  PreferConstrainedBoxOverContainerFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // For an unnamed constructor, `ConstructorName` and its `NamedType`
    // child share a source range and the covering node resolves to the
    // deeper one, so look up before type-testing.
    final targetNode = node.thisOrAncestorOfType<ConstructorName>() ?? node;
    if (targetNode is! ConstructorName) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(targetNode), 'ConstrainedBox');
    });
  }
}
