import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that replaces `.from()` with `.of()` on List/Set constructors.
class PreferIterableOfFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferIterableOf',
    DartFixKindPriority.standard,
    'Replace .from() with .of()',
  );

  PreferIterableOfFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;

    // Find the 'from' identifier to replace with 'of'
    final SimpleIdentifier? fromIdentifier = switch (targetNode) {
      InstanceCreationExpression(:final constructorName)
          when constructorName.name?.name == 'from' =>
        constructorName.name!,
      MethodInvocation(:final methodName) when methodName.name == 'from' =>
        methodName,
      _ => null,
    };

    if (fromIdentifier == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(fromIdentifier), 'of');
    });
  }
}
