import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

import '../fpdart_type_checkers.dart';

enum _Combinator {
  andThen(name: 'andThen', arity: 1),
  map(name: 'map', arity: 1),
  filterOrElse(name: 'filterOrElse', arity: 2);

  const _Combinator({required this.name, required this.arity});

  final String name;

  final int arity;

  static _Combinator? byName(String name) {
    for (final combinator in values) {
      if (combinator.name == name) return combinator;
    }

    return null;
  }
}

class ExpandToFlatMap extends ResolvedCorrectionProducer {
  static const _assistKind = AssistKind(
    'many_lints.assist.expandToFlatMap',
    30,
    "Expand to 'flatMap'",
  );

  ExpandToFlatMap({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => _assistKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final invocation = _enclosingCombinator();
    if (invocation == null) return;

    final combinator = _Combinator.byName(invocation.methodName.name);
    if (combinator == null) return;

    final arguments = invocation.argumentList.arguments;
    if (arguments.length != combinator.arity) return;

    final wrapper = _wrapperNameOf(invocation);
    if (wrapper == null) return;

    final replacement = switch (combinator) {
      _Combinator.andThen => _expandAndThen(arguments),
      _Combinator.map => _expandMap(arguments, wrapper),
      _Combinator.filterOrElse => _expandFilterOrElse(arguments, wrapper),
    };
    if (replacement == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        SourceRange(invocation.methodName.offset, invocation.methodName.length),
        'flatMap',
      );
      builder.addSimpleReplacement(
        SourceRange(
          invocation.argumentList.offset,
          invocation.argumentList.length,
        ),
        '($replacement)',
      );
    });
  }

  String? _expandAndThen(NodeList<Argument> arguments) {
    final then = arguments.single.argumentExpression;

    return '(_) => ${_invoked(then, const [])}';
  }

  String? _expandMap(NodeList<Argument> arguments, String wrapper) {
    final transform = arguments.single.argumentExpression;
    final parameter = _parameterNameOf(transform) ?? _freshName(transform);

    return '($parameter) => $wrapper.of(${_invoked(transform, [parameter])})';
  }

  String? _expandFilterOrElse(NodeList<Argument> arguments, String wrapper) {
    final predicate = arguments.first.argumentExpression;
    final onFalse = arguments.last.argumentExpression;

    final parameter = _parameterNameOf(predicate) ?? _freshName(predicate);
    final condition = _invoked(predicate, [parameter]);
    final failure = _invoked(onFalse, [parameter]);

    return '($parameter) => $condition '
        '? $wrapper.of($parameter) '
        ': $wrapper.left($failure)';
  }

  String _invoked(Expression callback, List<String> arguments) {
    if (callback is FunctionExpression) {
      final body = callback.body;
      final parameters = callback.parameters?.parameters;

      // Edge case: other parameter names would leave the inlined body reading a missing name
      if (body is ExpressionFunctionBody &&
          parameters != null &&
          parameters.length == arguments.length &&
          _namesMatch(parameters, arguments)) {
        return body.expression.toSource();
      }
    }

    return '${callback.toSource()}(${arguments.join(', ')})';
  }

  bool _namesMatch(
    NodeList<FormalParameter> parameters,
    List<String> arguments,
  ) {
    for (var index = 0; index < parameters.length; index++) {
      if (parameters[index].name?.lexeme != arguments[index]) return false;
    }

    return true;
  }

  String? _parameterNameOf(Expression callback) {
    if (callback is! FunctionExpression) return null;

    final parameters = callback.parameters?.parameters;
    if (parameters == null || parameters.length != 1) return null;

    return parameters.single.name?.lexeme;
  }

  String _freshName(AstNode context) {
    const base = 'value';

    final taken = <String>{};
    for (
      AstNode? current = context;
      current != null;
      current = current.parent
    ) {
      if (current case FunctionExpression(:final parameters?)) {
        for (final parameter in parameters.parameters) {
          final name = parameter.name?.lexeme;
          if (name != null) taken.add(name);
        }
      }
    }

    if (!taken.contains(base)) return base;

    for (var suffix = 2; ; suffix++) {
      final candidate = '$base$suffix';
      if (!taken.contains(candidate)) return candidate;
    }
  }

  MethodInvocation? _enclosingCombinator() {
    for (AstNode? current = node; current != null; current = current.parent) {
      if (current is! MethodInvocation) continue;
      if (_Combinator.byName(current.methodName.name) == null) continue;

      return current;
    }

    return null;
  }

  String? _wrapperNameOf(MethodInvocation invocation) {
    final type = invocation.staticType;
    if (type is! InterfaceType) return null;
    if (!anyFpdartChecker.isAssignableFromType(type)) return null;

    return type.element.name;
  }
}
