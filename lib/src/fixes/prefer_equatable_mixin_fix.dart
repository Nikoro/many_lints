import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../rules/prefer_equatable_mixin.dart';

class PreferEquatableMixinFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferEquatableMixin',
    DartFixKindPriority.standard,
    "Replace with 'with {0}'",
  );

  PreferEquatableMixinFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  List<String> get fixArguments => [_mixin ?? 'Equatable'];

  String? _mixin;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! ExtendsClause) return;

    final classDecl = targetNode.parent;
    if (classDecl is! ClassDeclaration) return;

    final superclass = targetNode.superclass.element;
    if (superclass is! ClassElement) return;
    final mixin = equatableMixinName(superclass, unitResult.libraryElement);
    if (mixin == null) return;
    _mixin = mixin;

    final withClause = classDecl.withClause;

    await builder.addDartFileEdit(file, (builder) {
      if (withClause != null) {
        builder.addDeletion(range.startStart(targetNode, withClause));
        final lastMixin = withClause.mixinTypes.last;
        builder.addSimpleInsertion(lastMixin.end, ', $mixin');
      } else {
        builder.addSimpleReplacement(range.node(targetNode), 'with $mixin');
      }
    });
  }
}
