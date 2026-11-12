import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

import '../fpdart_chain_call.dart';
import '../fpdart_type_checkers.dart';

class ConvertFlatMapToMap extends ResolvedCorrectionProducer {
  static const _assistKind = AssistKind(
    'many_lints.assist.convertFlatMapToMap',
    30,
    "Convert to 'map'",
  );

  static const _wrappingConstructors = {'right', 'of', 'some'};

  ConvertFlatMapToMap({required super.context});

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

    final wrapped = _unwrapped(body);
    if (wrapped == null) return;

    final parameter = call.parameter?.name?.lexeme;
    final replacement = _argumentFor(wrapped, parameter);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        SourceRange(
          call.invocation.methodName.offset,
          call.invocation.methodName.length,
        ),
        'map',
      );
      builder.addSimpleReplacement(
        SourceRange(call.callback.offset, call.callback.length),
        replacement,
      );
    });
  }

  Expression? _unwrapped(Expression body) {
    if (body is InstanceCreationExpression) {
      final name = body.constructorName.name?.name;
      if (name == null || !_wrappingConstructors.contains(name)) return null;
      if (!_isFpdartType(body)) return null;

      return _singleArgumentOf(body.argumentList);
    }

    if (body is MethodInvocation) {
      if (!_wrappingConstructors.contains(body.methodName.name)) return null;
      if (!_isFpdartType(body)) return null;

      return _singleArgumentOf(body.argumentList);
    }

    return null;
  }

  Expression? _singleArgumentOf(ArgumentList arguments) {
    final positional = arguments.arguments;
    if (positional.length != 1) return null;

    final argument = positional.single;
    return argument is NamedArgument ? null : argument.argumentExpression;
  }

  bool _isFpdartType(Expression expression) {
    final type = expression.staticType;
    return type != null && anyFpdartChecker.isAssignableFromType(type);
  }

  String _argumentFor(Expression wrapped, String? parameter) {
    if (parameter != null &&
        wrapped is MethodInvocation &&
        wrapped.typeArguments == null &&
        wrapped.realTarget == null) {
      final arguments = wrapped.argumentList.arguments;
      if (arguments.length == 1) {
        final only = arguments.single.argumentExpression;
        if (only is SimpleIdentifier && only.name == parameter) {
          return wrapped.methodName.name;
        }
      }
    }

    final name = parameter ?? '_';
    return '($name) => ${wrapped.toSource()}';
  }
}
