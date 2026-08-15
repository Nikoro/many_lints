import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Fix that adds the `@immutable` annotation to a state class.
///
/// Shared by `prefer_immutable_bloc_state` and `prefer_immutable_state`: the
/// edit is the same whichever rule decided the class holds state.
class AddImmutableAnnotationFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.addImmutableAnnotation',
    DartFixKindPriority.standard,
    "Add '@immutable' annotation",
  );

  AddImmutableAnnotationFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // The rule reports at the class-name token, so the covering node is the
    // declaration (or a name-part wrapper) rather than an identifier.
    final classDecl = node.thisOrAncestorOfType<ClassDeclaration>();
    if (classDecl == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.importLibrary(Uri.parse('package:meta/meta.dart'));
      builder.addSimpleInsertion(classDecl.offset, '@immutable\n');
    });
  }
}
