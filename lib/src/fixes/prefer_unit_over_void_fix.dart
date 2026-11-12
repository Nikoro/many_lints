import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class PreferUnitOverVoidFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferUnitOverVoid',
    DartFixKindPriority.standard,
    "Replace 'void' with 'Unit'",
  );

  PreferUnitOverVoidFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossSingleFile;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node.thisOrAncestorOfType<NamedType>();
    if (targetNode == null) return;

    await builder.addDartFileEdit(file, (builder) {
      // Edge case: the file may reach fpdart types through a library that does not export Unit
      builder.importLibrary(Uri.parse('package:fpdart/fpdart.dart'));
      builder.addSimpleReplacement(range.node(targetNode), 'Unit');
    });
  }
}
