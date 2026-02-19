import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Fix that adds the `@immutable` annotation to a Bloc state class.
class PreferImmutableBlocStateFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferImmutableBlocState',
    DartFixKindPriority.standard,
    "Add '@immutable' annotation",
  );

  PreferImmutableBlocStateFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! SimpleIdentifier) return;

    final classDecl = targetNode.parent;
    if (classDecl is! ClassDeclaration) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.importLibrary(Uri.parse('package:meta/meta.dart'));
      builder.addSimpleInsertion(classDecl.offset, '@immutable\n');
    });
  }
}
