import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

import '../fpdart_chain_call.dart';

/// Converts `flatMap((_) => next())` to `andThen(next)`.
///
/// `andThen` is declared as exactly `flatMap((_) => then())` in fpdart, so the
/// conversion is not a behaviour change — it is the same call under the name
/// that says what it does. The long form is simply what you reach for when
/// `flatMap` is the only chaining tool in mind, which is why the same two-line
/// shape turns up across unrelated features in one codebase.
///
/// ```dart
/// resetter.reset().flatMap((_) => authRepository.logout())
/// ```
///
/// becomes
///
/// ```dart
/// resetter.reset().andThen(authRepository.logout)
/// ```
///
/// Two output shapes: a callback whose body is a bare invocation needing
/// nothing from the closure becomes a tear-off, and anything else keeps a
/// thunk (`andThen(() => …)`).
///
/// ## Declines when the parameter is used
///
/// A callback that reads its argument has a real dependency on the previous
/// step's value, and `andThen` throws that value away. Offering the conversion
/// there would silently drop it, so the assist checks by element rather than
/// by the `_` spelling — a named-but-unused parameter is the same situation,
/// and a used one is disqualifying whatever it is called.
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

    // The whole point of `andThen` is that the previous value is not needed.
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
