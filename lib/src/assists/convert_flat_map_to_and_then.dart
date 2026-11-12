import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

import '../fpdart_chain_call.dart';

class ConvertFlatMapToAndThen extends ResolvedCorrectionProducer {
  static const _assistKind = AssistKind(
    'many_lints.assist.convertFlatMapToAndThen',
    30,
    "Convert to 'andThen'",
  );

  ConvertFlatMapToAndThen({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => _assistKind;

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
