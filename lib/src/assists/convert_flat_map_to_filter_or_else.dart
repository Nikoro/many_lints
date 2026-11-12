import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

import '../fpdart_chain_call.dart';
import '../fpdart_type_checkers.dart';

class ConvertFlatMapToFilterOrElse extends ResolvedCorrectionProducer {
  static const _assistKind = AssistKind(
    'many_lints.assist.convertFlatMapToFilterOrElse',
    30,
    "Convert to 'filterOrElse'",
  );

  static const _successConstructors = {'right', 'of', 'some'};

  ConvertFlatMapToFilterOrElse({required super.context});

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
    if (body is! ConditionalExpression) return;

    final parameter = call.parameter?.name?.lexeme;
    if (parameter == null) return;

    final failure = _failureFor(body, parameter);
    if (failure == null) return;

    final (:condition, :onFalse) = failure;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        SourceRange(
          call.invocation.methodName.offset,
          call.invocation.methodName.length,
        ),
        'filterOrElse',
      );
      builder.addSimpleReplacement(
        SourceRange(call.callback.offset, call.callback.length),
        '($parameter) => $condition, ($parameter) => $onFalse',
      );
    });
  }

  ({String condition, String onFalse})? _failureFor(
    ConditionalExpression body,
    String parameter,
  ) {
    final then = body.thenExpression;
    final otherwise = body.elseExpression;

    if (_passesThrough(then, parameter)) {
      final failure = _leftArgument(otherwise);
      if (failure == null) return null;

      return (condition: body.condition.toSource(), onFalse: failure);
    }

    if (_passesThrough(otherwise, parameter)) {
      final failure = _leftArgument(then);
      if (failure == null) return null;

      return (condition: _negated(body.condition), onFalse: failure);
    }

    return null;
  }

  bool _passesThrough(Expression expression, String parameter) {
    final wrapped = _wrappedArgument(expression, _successConstructors);
    return wrapped is SimpleIdentifier && wrapped.name == parameter;
  }

  String? _leftArgument(Expression expression) =>
      _wrappedArgument(expression, const {'left'})?.toSource();

  Expression? _wrappedArgument(Expression expression, Set<String> names) {
    final ArgumentList arguments;

    switch (expression) {
      case InstanceCreationExpression(:final constructorName):
        final name = constructorName.name?.name;
        if (name == null || !names.contains(name)) return null;
        arguments = expression.argumentList;
      case MethodInvocation(:final methodName):
        if (!names.contains(methodName.name)) return null;
        arguments = expression.argumentList;
      default:
        return null;
    }

    final type = expression.staticType;
    if (type == null || !anyFpdartChecker.isAssignableFromType(type)) {
      return null;
    }

    final positional = arguments.arguments;
    if (positional.length != 1) return null;

    final argument = positional.single;
    return argument is NamedArgument ? null : argument.argumentExpression;
  }

  String _negated(Expression condition) {
    if (condition is PrefixExpression && condition.operator.lexeme == '!') {
      return condition.operand.toSource();
    }

    return condition is BinaryExpression
        ? '!(${condition.toSource()})'
        : '!${condition.toSource()}';
  }
}
