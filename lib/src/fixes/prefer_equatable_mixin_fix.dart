import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that replaces `extends Equatable` with `with EquatableMixin`.
class PreferEquatableMixinFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferEquatableMixin',
    DartFixKindPriority.standard,
    "Replace with 'with EquatableMixin'",
  );

  PreferEquatableMixinFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! ExtendsClause) return;

    final classDecl = targetNode.parent;
    if (classDecl is! ClassDeclaration) return;

    final withClause = classDecl.withClause;

    await builder.addDartFileEdit(file, (builder) {
      if (withClause != null) {
        // Has existing `with` clause: remove `extends Equatable` and append
        // EquatableMixin to the existing `with` clause.
        builder.addDeletion(range.startStart(targetNode, withClause));
        final lastMixin = withClause.mixinTypes.last;
        builder.addSimpleInsertion(lastMixin.end, ', EquatableMixin');
      } else {
        // No `with` clause: replace `extends Equatable` with
        // `with EquatableMixin`.
        builder.addSimpleReplacement(
          range.node(targetNode),
          'with EquatableMixin',
        );
      }
    });
  }
}
