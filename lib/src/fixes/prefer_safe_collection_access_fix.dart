import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

const _accessorReplacements = {
  'first': 'head',
  'last': 'lastOption',
  'single': 'singleOption',
};

class PreferSafeCollectionAccessFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferSafeCollectionAccess',
    DartFixKindPriority.standard,
    "Replace with the total accessor",
  );

  PreferSafeCollectionAccessFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final property = node.thisOrAncestorOfType<SimpleIdentifier>();
    if (property == null) return;

    final replacement = _accessorReplacements[property.name];
    // Edge case: an `accessors:` entry has no known counterpart, so it warns without a fix
    if (replacement == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.importLibrary(Uri.parse('package:fpdart/fpdart.dart'));
      builder.addSimpleReplacement(range.node(property), replacement);
    });
  }
}
