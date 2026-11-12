import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

import '../fpdart_chain_call.dart';
import '../fpdart_type_checkers.dart';
import '../type_checker.dart';

class ConvertReduceToSequenceList extends ResolvedCorrectionProducer {
  static const _assistKind = AssistKind(
    'many_lints.assist.convertReduceToSequenceList',
    // Edge case: ranked below the exact conversions because it changes behaviour
    29,
    "Convert to 'sequenceListSeq' (runs every task after a failure)",
  );

  static const _iterableChecker = TypeChecker.fromUrl('dart:core#Iterable');
  static const _listChecker = TypeChecker.fromUrl('dart:core#List');

  static const _sequencedChecker = TypeChecker.any([
    taskChecker,
    taskOptionChecker,
    taskEitherChecker,
  ]);

  ConvertReduceToSequenceList({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => _assistKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final reduce = _enclosingReduce();
    if (reduce == null) return;

    final list = reduce.realTarget;
    if (list == null) return;

    final wrapper = _sequencedWrapperOf(list);
    if (wrapper == null) return;

    if (!_chainsAccumulator(reduce)) return;

    // Edge case: sequenceListSeq yields every value where reduce yields only the last
    final source = switch (list.staticType) {
      final type? when _listChecker.isAssignableFromType(type) =>
        list.toSource(),
      _ => '${list.toSource()}.toList()',
    };
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        SourceRange(reduce.offset, reduce.length),
        '$wrapper.sequenceListSeq($source).map((values) => values.last)',
      );
    });
  }

  MethodInvocation? _enclosingReduce() {
    for (AstNode? current = node; current != null; current = current.parent) {
      if (current is MethodInvocation && current.methodName.name == 'reduce') {
        return current;
      }
    }

    return null;
  }

  String? _sequencedWrapperOf(Expression list) {
    final type = list.staticType;
    if (type is! InterfaceType) return null;
    if (!_iterableChecker.isAssignableFromType(type)) return null;

    final element = _elementTypeOf(type);
    if (element is! InterfaceType) return null;
    if (!_sequencedChecker.isExactlyType(element)) return null;

    return element.element.name;
  }

  DartType? _elementTypeOf(InterfaceType type) {
    for (final candidate in [type, ...type.allSupertypes]) {
      if (!_iterableChecker.isExactlyType(candidate)) continue;

      final arguments = candidate.typeArguments;
      if (arguments.length == 1) return arguments.single;
    }

    return null;
  }

  bool _chainsAccumulator(MethodInvocation reduce) {
    final arguments = reduce.argumentList.arguments;
    if (arguments.length != 1) return false;

    final callback = arguments.single.argumentExpression;
    if (callback is! FunctionExpression) return false;

    final parameters = callback.parameters?.parameters;
    if (parameters == null || parameters.length != 2) return false;

    final accumulator = parameters.first.name?.lexeme;
    final next = parameters.last.name?.lexeme;
    if (accumulator == null || next == null) return false;

    final body = callback.body;
    if (body is! ExpressionFunctionBody) return false;

    final chain = readFpdartFlatMap(body.expression);
    if (chain == null || chain.invocation != body.expression) return false;

    final target = chain.invocation.realTarget;
    if (target is! SimpleIdentifier || target.name != accumulator) return false;

    final chained = chain.body;
    if (chained == null) return false;
    if (!parameterIsUnused(chain.parameter, chained)) return false;

    return chained is SimpleIdentifier && chained.name == next;
  }
}
