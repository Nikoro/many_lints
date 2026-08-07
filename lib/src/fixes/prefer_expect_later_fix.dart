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
    // The covering node may be the invocation itself rather than its name
    // identifier, so walk up instead of type-testing `node`.
    final methodInvocation = node.thisOrAncestorOfType<MethodInvocation>();
    if (methodInvocation == null) return;

    // Determine if already preceded by `await`
    final parent = methodInvocation.parent;
    final alreadyAwaited =
        parent is AwaitExpression && parent.expression == methodInvocation;

    // `await ` would be inserted at the same offset the method name starts
    // at, and two edits sharing an offset raise ConflictingEditException —
    // which FixProcessor swallows, dropping the whole fix. Emit one edit.
    final replacement = alreadyAwaited ? 'expectLater' : 'await expectLater';

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.node(methodInvocation.methodName),
        replacement,
      );
    });
  }
}
