import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that replaces a `void` fpdart type argument with `Unit`.
///
/// The edit is a single token swap, so it is safe to apply in bulk across a
/// file: `Unit` is a real value where `void` is not, and every use site that
/// compiled against `void` still compiles against `Unit`.
///
/// The one thing it cannot do is fill in the *value*. A body that ends without
/// returning anything will not compile once the type says `Unit`, and the
/// author has to write `return unit;`. That is deliberate — the alternative is
/// guessing where in an arbitrary body the return belongs, and a fix that
/// rewrites control flow to satisfy a type annotation is not one anybody
/// should apply without reading it.
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
    // The rule reports the `void` type argument itself.
    final targetNode = node.thisOrAncestorOfType<NamedType>();
    if (targetNode == null) return;

    await builder.addDartFileEdit(file, (builder) {
      // `Unit` is fpdart's, and the file may name the fpdart types through a
      // library that does not re-export it, so the import cannot be assumed.
      builder.importLibrary(Uri.parse('package:fpdart/fpdart.dart'));
      builder.addSimpleReplacement(range.node(targetNode), 'Unit');
    });
  }
}
