import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class PreferReturningShorthandsFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferReturningShorthands',
    DartFixKindPriority.standard,
    'Replace with dot shorthand',
  );

  PreferReturningShorthandsFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  String get unnamedConstructorReplacement => 'new';

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // Edge case: an unnamed ConstructorName shares its range with the deeper NamedType
    final targetNode = node.thisOrAncestorOfType<ConstructorName>() ?? node;

    if (targetNode is SimpleIdentifier) {
      final parent = targetNode.parent;
      if (parent is MethodInvocation && parent.target == targetNode) {
        final methodName = parent.methodName.name;
        final replacement = '.$methodName';

        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleReplacement(
            range.startStart(targetNode, parent.argumentList),
            replacement,
          );
        });
        return;
      }
    }

    if (targetNode is ConstructorName) {
      final constructorNameText =
          targetNode.name?.name ?? unnamedConstructorReplacement;
      final replacement = constructorNameText.isEmpty
          ? '.'
          : '.$constructorNameText';

      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.node(targetNode), replacement);
      });
    }
  }
}
