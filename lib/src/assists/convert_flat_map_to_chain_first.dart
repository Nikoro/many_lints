import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

import '../fpdart_chain_call.dart';

class ConvertFlatMapToChainFirst extends ResolvedCorrectionProducer {
  static const _assistKind = AssistKind(
    'many_lints.assist.convertFlatMapToChainFirst',
    // Edge case: ranked below the exact conversions because it changes behaviour
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

    final returned = inner.expression;
    if (returned is! SimpleIdentifier || returned.name != parameter) {
      return null;
    }

    // Edge case: an inner callback that reads its argument was not discarding the value
    final innerParameters = callback.parameters?.parameters;
    final innerParameter = innerParameters == null || innerParameters.isEmpty
        ? null
        : innerParameters.single;
    if (!parameterIsUnused(innerParameter, inner)) return null;

    return _tearOffOrThunk(effect, parameter);
  }

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
