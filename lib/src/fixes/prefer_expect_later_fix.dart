import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that replaces `expect(future, ...)` with `await expectLater(future, ...)`.
class PreferExpectLaterFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferExpectLater',
    DartFixKindPriority.standard,
    "Replace with 'await expectLater'",
  );

  PreferExpectLaterFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! SimpleIdentifier) return;

    final methodInvocation = targetNode.parent;
    if (methodInvocation is! MethodInvocation) return;

    // Determine if already preceded by `await`
    final parent = methodInvocation.parent;
    final alreadyAwaited =
        parent is AwaitExpression && parent.expression == methodInvocation;

    await builder.addDartFileEdit(file, (builder) {
      // Replace `expect` with `expectLater`
      builder.addSimpleReplacement(range.node(targetNode), 'expectLater');

      // Add `await` if not already awaited
      if (!alreadyAwaited) {
        builder.addSimpleInsertion(methodInvocation.offset, 'await ');
      }
    });
  }
}
