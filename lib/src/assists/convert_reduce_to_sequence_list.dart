import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

import '../fpdart_chain_call.dart';
import '../fpdart_type_checkers.dart';
import '../type_checker.dart';

/// Converts a hand-rolled `reduce` over a list of tasks into
/// `TaskEither.sequenceListSeq`.
///
/// ```dart
/// tasks.reduce((acc, t) => acc.flatMap((_) => t))
/// ```
///
/// becomes
///
/// ```dart
/// TaskEither.sequenceListSeq(tasks)
/// ```
///
/// The hand-rolled version also needs an empty-list guard, because `reduce`
/// throws on an empty iterable; `sequenceListSeq` does not. That is one more
/// reason to prefer the library version, and the guard is usually the bug the
/// long form ships with.
///
/// ## Always the `Seq` variant
///
/// `sequenceList` runs its tasks **concurrently**; `sequenceListSeq` runs them
/// in order. A `reduce` that chains each element onto the accumulator is
/// inherently sequential — element two cannot start until element one
/// finishes — so only the `Seq` variant preserves behaviour. Offering the
/// concurrent one would change when effects run, and in what order.
class ConvertReduceToSequenceList extends ResolvedCorrectionProducer {
  static const _assistKind = AssistKind(
    'many_lints.assist.convertReduceToSequenceList',
    30,
    "Convert to 'sequenceListSeq'",
  );

  static const _iterableChecker = TypeChecker.fromUrl('dart:core#Iterable');

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

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        SourceRange(reduce.offset, reduce.length),
        '$wrapper.sequenceListSeq(${list.toSource()})',
      );
    });
  }

  /// The `reduce` invocation at or above the cursor.
  MethodInvocation? _enclosingReduce() {
    for (AstNode? current = node; current != null; current = current.parent) {
      if (current is MethodInvocation && current.methodName.name == 'reduce') {
        return current;
      }
    }

    return null;
  }

  /// The name of the fpdart wrapper held by [list], or `null` when [list] is
  /// not an iterable of one.
  ///
  /// Returns the wrapper's *element* name — `TaskEither` — because the
  /// replacement calls a static on it.
  String? _sequencedWrapperOf(Expression list) {
    final type = list.staticType;
    if (type is! InterfaceType) return null;
    if (!_iterableChecker.isAssignableFromType(type)) return null;

    // The element type comes from the `Iterable<E>` in the supertype chain,
    // so a `List<TaskEither<..>>` resolves the same as a bare `Iterable`.
    final element = _elementTypeOf(type);
    if (element is! InterfaceType) return null;
    if (!anyFpdartChecker.isAssignableFromType(element)) return null;

    return element.element.name;
  }

  /// The `E` of the `Iterable<E>` [type] implements, or `null`.
  DartType? _elementTypeOf(InterfaceType type) {
    for (final candidate in [type, ...type.allSupertypes]) {
      if (!_iterableChecker.isExactlyType(candidate)) continue;

      final arguments = candidate.typeArguments;
      if (arguments.length == 1) return arguments.single;
    }

    return null;
  }

  /// Whether [reduce]'s callback is `(acc, next) => acc.flatMap((_) => next)`.
  ///
  /// Anything else is a different fold and must not be rewritten: the shape is
  /// what makes the conversion exact.
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

    // The receiver must be the accumulator...
    final target = chain.invocation.realTarget;
    if (target is! SimpleIdentifier || target.name != accumulator) return false;

    // ...the callback must ignore the accumulated value...
    final chained = chain.body;
    if (chained == null) return false;
    if (!parameterIsUnused(chain.parameter, chained)) return false;

    // ...and it must return the element being folded in, unchanged.
    return chained is SimpleIdentifier && chained.name == next;
  }
}
