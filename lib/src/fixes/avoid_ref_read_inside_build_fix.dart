import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that turns a one-off provider read inside `build` into a subscribing
/// one — `ref.read(...)` to `ref.watch(...)`, and provider's `context.read<T>()`
/// to `context.watch<T>()`.
///
/// Only the method name is rewritten, which is why one fix serves both: the
/// receiver, the type arguments and the arguments are all left as written.
class AvoidRefReadInsideBuildFix extends ResolvedCorrectionProducer {
  /// Named for the operation rather than the receiver.
  ///
  /// `registerFixForRule` builds the producer once at registration and throws
  /// if `fixKind` is null, so the kind cannot depend on which ecosystem the
  /// call belongs to. A label saying `ref.watch` would name an API a
  /// package:provider user does not have.
  static const _fixKind = FixKind(
    'many_lints.fix.avoidRefReadInsideBuild',
    DartFixKindPriority.standard,
    "Replace with 'watch'",
  );

  AvoidRefReadInsideBuildFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! MethodInvocation) return;
    if (targetNode.methodName.name != 'read') return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(targetNode.methodName), 'watch');
    });
  }
}
