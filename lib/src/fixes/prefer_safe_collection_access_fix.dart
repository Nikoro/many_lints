import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// The total accessor that replaces each throwing one.
const _accessorReplacements = {
  'first': 'head',
  'last': 'lastOption',
  'single': 'singleOption',
};

/// Fix that swaps a throwing collection accessor for fpdart's total one.
///
/// The edit is deliberately `singleLocation` rather than file-wide. Unlike the
/// other fixes in this family it **changes the expression's type**: `first`
/// yields `T`, `head` yields `Option<T>`. Every use site therefore has to be
/// adjusted too — usually by continuing the pipeline with `getOrElse`,
/// `toEither` or a `match`. Applying that in bulk would leave a file full of
/// type errors for the author to untangle, so the fix stays one at a time,
/// where the follow-up edit is right there on screen.
///
/// The type change is the point of the rule, not a side effect: it is what
/// forces the empty case to be handled rather than thrown.
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
    // The rule reports the property name itself, so the covering node is the
    // identifier rather than the whole access.
    final property = node.thisOrAncestorOfType<SimpleIdentifier>();
    if (property == null) return;

    final replacement = _accessorReplacements[property.name];
    // A name added through `accessors:` has no known counterpart to swap in,
    // so the rule still warns but no fix is offered.
    if (replacement == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.importLibrary(Uri.parse('package:fpdart/fpdart.dart'));
      builder.addSimpleReplacement(range.node(property), replacement);
    });
  }
}
