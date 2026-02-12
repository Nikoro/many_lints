import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that replaces explicit class constructor invocation with dot shorthand.
///
/// Transforms `EdgeInsets.symmetric(...)` into `.symmetric(...)`.
class PreferShorthandsWithConstructorsFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferShorthandsWithConstructors',
    DartFixKindPriority.standard,
    'Replace with dot shorthand',
  );

  PreferShorthandsWithConstructorsFix({required super.context});

  @override
  CorrectionApplicability get applicability => CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;

    // Handle MethodInvocation case (e.g., EdgeInsets.symmetric)
    if (targetNode is SimpleIdentifier) {
      final parent = targetNode.parent;
      if (parent is MethodInvocation && parent.target == targetNode) {
        // This is the class name part of "EdgeInsets.symmetric"
        final methodName = parent.methodName.name;
        final replacement = '.$methodName';

        await builder.addDartFileEdit(file, (builder) {
          // Replace "EdgeInsets.symmetric" with ".symmetric"
          builder.addSimpleReplacement(range.startStart(targetNode, parent.argumentList), replacement);
        });
        return;
      }
    }

    // Handle ConstructorName case (for new expressions)
    if (targetNode is ConstructorName) {
      final constructorNameText = targetNode.name?.name ?? '';
      final replacement = constructorNameText.isEmpty ? '.' : '.$constructorNameText';

      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.node(targetNode), replacement);
      });
    }
  }
}
