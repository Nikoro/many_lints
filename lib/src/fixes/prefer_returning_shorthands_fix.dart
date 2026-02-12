import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that replaces explicit class constructor invocation with dot shorthand.
///
/// Transforms `SomeClass('val')` into `.new('val')` and
/// `SomeClass.named('val')` into `.named('val')`.
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

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;

    // Handle MethodInvocation case (e.g., SomeClass.named)
    if (targetNode is SimpleIdentifier) {
      final parent = targetNode.parent;
      if (parent is MethodInvocation && parent.target == targetNode) {
        // This is the class name part of "SomeClass.named"
        final methodName = parent.methodName.name;
        final replacement = '.$methodName';

        await builder.addDartFileEdit(file, (builder) {
          // Replace "SomeClass.named" with ".named"
          builder.addSimpleReplacement(
            range.startStart(targetNode, parent.argumentList),
            replacement,
          );
        });
        return;
      }
    }

    // Handle ConstructorName case (for new expressions)
    if (targetNode is ConstructorName) {
      final constructorNameText = targetNode.name?.name ?? 'new';
      final replacement = '.$constructorNameText';

      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.node(targetNode), replacement);
      });
    }
  }
}
