import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class AvoidDuplicateCollectionElementsFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidDuplicateCollectionElements',
    DartFixKindPriority.standard,
    'Remove duplicate element',
  );

  AvoidDuplicateCollectionElementsFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final element = _reportedElement();
    if (element == null) return;

    final elements = switch (element.parent) {
      ListLiteral(:final elements) => elements,
      SetOrMapLiteral(:final elements) => elements,
      _ => null,
    };
    if (elements == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(range.nodeInList(elements, element));
    });
  }

  CollectionElement? _reportedElement() {
    for (AstNode? current = node; current != null; current = current.parent) {
      final parent = current.parent;
      if (parent is ListLiteral || parent is SetOrMapLiteral) {
        return current is CollectionElement ? current : null;
      }
    }
    return null;
  }
}
