import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

import '../fpdart_chain_call.dart';

/// Converts `flatMap((v) => effect(v).map((_) => v))` to `chainFirst(effect)`
/// — the "run an effect, keep the original value" shape.
///
/// ```dart
/// pipeline.flatMap((user) => audit(user).map((_) => user))
/// ```
///
/// becomes
///
/// ```dart
/// pipeline.chainFirst(audit)
/// ```
///
/// ## This one changes behaviour, and says so
///
/// Unlike the other `flatMap`-narrowing assists, this is **not** an exact
/// translation. fpdart declares:
///
/// ```dart
/// TaskEither<L, R> chainFirst<C>(TaskEither<L, C> Function(R b) chain) =>
///     flatMap((b) => chain(b).map((c) => b).orElse((l) => TaskEither.right(b)));
/// ```
///
/// That trailing `orElse` means `chainFirst` **swallows a failure in the
/// effect**: if `audit` fails, the pipeline carries on with the original value.
/// The hand-written long form almost never does that — it propagates the
/// failure, which is usually what its author intended.
///
/// So the conversion is offered under a message that names the difference
/// rather than a generic "convert to", because the lightbulb text is the only
/// place a reader learns that error handling is about to change. An assist
/// that hid this would be worse than no assist: the long form looks equivalent,
/// which is exactly why the difference is easy to miss on review.
class ConvertFlatMapToChainFirst extends ResolvedCorrectionProducer {
  static const _assistKind = AssistKind(
    'many_lints.assist.convertFlatMapToChainFirst',
    // Below the exact conversions: this one asks the author to accept a
    // change in behaviour, so it should not sit above assists that do not.
    29,
    "Convert to 'chainFirst' (ignores the effect's failure)",
  );

  ConvertFlatMapToChainFirst({required super.context});

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

    final parameter = call.parameter?.name?.lexeme;
    if (parameter == null) return;

    final effect = _effectKeepingOriginal(body, parameter);
    if (effect == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        SourceRange(
          call.invocation.methodName.offset,
          call.invocation.methodName.length,
        ),
        'chainFirst',
      );
      builder.addSimpleReplacement(
        SourceRange(call.callback.offset, call.callback.length),
        effect,
      );
    });
  }

  /// The effect source for `effect(v).map((_) => v)`, or `null` when [body] is
  /// not that shape.
  ///
  /// The inner `map` must discard its own argument and return exactly the
  /// outer callback's parameter — that is what makes it "keep the original
  /// value" rather than an ordinary transformation.
  String? _effectKeepingOriginal(Expression body, String parameter) {
    if (body is! MethodInvocation) return null;
    if (body.methodName.name != 'map') return null;

    final effect = body.realTarget;
    if (effect == null) return null;

    final arguments = body.argumentList.arguments;
    if (arguments.length != 1) return null;

    final callback = arguments.single.argumentExpression;
    if (callback is! FunctionExpression) return null;

    final inner = callback.body;
    if (inner is! ExpressionFunctionBody) return null;

    // The inner callback must return the OUTER parameter, unchanged.
    final returned = inner.expression;
    if (returned is! SimpleIdentifier || returned.name != parameter) {
      return null;
    }

    // ...and must not depend on its own argument, or the value it discards
    // was doing something after all.
    final innerParameters = callback.parameters?.parameters;
    final innerParameter = innerParameters == null || innerParameters.isEmpty
        ? null
        : innerParameters.single;
    if (!parameterIsUnused(innerParameter, inner)) return null;

    return _tearOffOrThunk(effect, parameter);
  }

  /// `effect` as a tear-off when it is exactly `effect(v)`, else a closure.
  String _tearOffOrThunk(Expression effect, String parameter) {
    if (effect is MethodInvocation && effect.typeArguments == null) {
      final arguments = effect.argumentList.arguments;
      if (arguments.length == 1) {
        final only = arguments.single.argumentExpression;
        if (only is SimpleIdentifier && only.name == parameter) {
          final target = effect.realTarget;
          final receiver = target == null ? '' : '${target.toSource()}.';

          return '$receiver${effect.methodName.name}';
        }
      }
    }

    return '($parameter) => ${effect.toSource()}';
  }
}
