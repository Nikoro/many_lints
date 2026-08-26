import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

import '../fpdart_chain_call.dart';

/// Replaces `flatMap((_) => next())` with `andThen(next)`.
///
/// Shares [andThenArgumentFor] with the assist of the same name, so the two
/// cannot disagree about when a tear-off is emitted.
class PreferAndThenFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferAndThen',
    DartFixKindPriority.standard,
    "Replace with 'andThen'",
  );

  PreferAndThenFix({required super.context});

  /// The rewrite is mechanical and semantics-preserving, so applying it
  /// everywhere at once is safe.
  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final call = readFpdartFlatMap(node);
    if (call == null) return;

    final body = call.body;
    if (body == null) return;

    if (!parameterIsUnused(call.parameter, body)) return;

    final replacement = andThenArgumentFor(body);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        SourceRange(
          call.invocation.methodName.offset,
          call.invocation.methodName.length,
        ),
        'andThen',
      );
      builder.addSimpleReplacement(
        SourceRange(call.callback.offset, call.callback.length),
        replacement,
      );
    });
  }
}
