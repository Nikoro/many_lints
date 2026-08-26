import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

import '../fpdart_type_checkers.dart';

/// The narrow combinator being expanded.
enum _Combinator {
  andThen(name: 'andThen', arity: 1),
  map(name: 'map', arity: 1),
  filterOrElse(name: 'filterOrElse', arity: 2);

  const _Combinator({required this.name, required this.arity});

  /// The method name this entry expands.
  final String name;

  /// How many arguments it takes, which is what separates `filterOrElse` from
  /// the two single-callback forms.
  final int arity;

  static _Combinator? byName(String name) {
    for (final combinator in values) {
      if (combinator.name == name) return combinator;
    }

    return null;
  }
}

/// Expands `andThen`, `map` or `filterOrElse` back into the `flatMap` each one
/// is defined as.
///
/// The inverse of the three exact narrowing assists. fpdart declares all three
/// in terms of `flatMap`, so both directions preserve meaning:
///
/// ```dart
/// andThen(then)        => flatMap((_) => then());
/// map(f)               => flatMap((v) => Wrapper.of(f(v)));
/// filterOrElse(f, on)  => flatMap((r) => f(r) ? Wrapper.of(r) : Wrapper.left(on(r)));
/// ```
///
/// ## Why go backwards at all
///
/// Because the narrow forms hide the previous value, and sometimes you need it
/// again. You write `andThen(logout)`, then the next step turns out to depend
/// on what came before — the first edit is always expanding back to a
/// `flatMap` whose callback names that value. This assist is that edit.
///
/// ## The two that have no inverse here
///
/// `chainFirst` and `sequenceListSeq` are deliberately absent.
///
/// Expanding `chainFirst` honestly means emitting its `orElse` too:
///
/// ```dart
/// flatMap((b) => audit(b).map((_) => b).orElse((l) => TaskEither.right(b)))
/// ```
///
/// which nobody wants to read — while the shorter form people expect silently
/// drops the failure-swallowing, which is the very trap
/// `ConvertFlatMapToChainFirst` warns about. Either output is worse than no
/// assist.
///
/// `sequenceListSeq` would expand to a hand-rolled fold that needs an
/// empty-list guard `reduce` does not supply. That is a downgrade in every
/// case, so it is not offered.
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

  /// `flatMap((_) => then())`.
  ///
  /// The parameter is `_` because `andThen` never had one to name: the whole
  /// point of the narrow form is that the previous value is unused.
  String? _expandAndThen(NodeList<Argument> arguments) {
    final then = arguments.single.argumentExpression;

    return '(_) => ${_invoked(then, const [])}';
  }

  /// `flatMap((value) => Wrapper.of(f(value)))`.
  String? _expandMap(NodeList<Argument> arguments, String wrapper) {
    final transform = arguments.single.argumentExpression;
    final parameter = _parameterNameOf(transform) ?? _freshName(transform);

    return '($parameter) => $wrapper.of(${_invoked(transform, [parameter])})';
  }

  /// `flatMap((value) => cond ? Wrapper.of(value) : Wrapper.left(onFalse))`.
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

  /// [callback] applied to [arguments], inlining a closure body where possible.
  ///
  /// A tear-off becomes a call (`logout` → `logout()`); a closure whose
  /// parameters are already the names being passed has its body inlined, so
  /// the result reads as the expression the author wrote rather than as an
  /// immediately-invoked lambda.
  String _invoked(Expression callback, List<String> arguments) {
    if (callback is FunctionExpression) {
      final body = callback.body;
      final parameters = callback.parameters?.parameters;

      // Only inline when the closure's own parameter names are the ones the
      // expansion binds; otherwise the body would reference a name that no
      // longer exists.
      if (body is ExpressionFunctionBody &&
          parameters != null &&
          parameters.length == arguments.length &&
          _namesMatch(parameters, arguments)) {
        return body.expression.toSource();
      }
    }

    return '${callback.toSource()}(${arguments.join(', ')})';
  }

  /// Whether [parameters] are named exactly [arguments], in order.
  bool _namesMatch(
    NodeList<FormalParameter> parameters,
    List<String> arguments,
  ) {
    for (var index = 0; index < parameters.length; index++) {
      if (parameters[index].name?.lexeme != arguments[index]) return false;
    }

    return true;
  }

  /// The single parameter name of [callback], when it is a closure declaring
  /// one.
  String? _parameterNameOf(Expression callback) {
    if (callback is! FunctionExpression) return null;

    final parameters = callback.parameters?.parameters;
    if (parameters == null || parameters.length != 1) return null;

    return parameters.single.name?.lexeme;
  }

  /// A parameter name for a tear-off, which brought none of its own.
  ///
  /// `value` unless something already in scope at [context] uses it, in which
  /// case the name is suffixed rather than shadowing.
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

  /// The combinator invocation at or above the cursor.
  MethodInvocation? _enclosingCombinator() {
    for (AstNode? current = node; current != null; current = current.parent) {
      if (current is! MethodInvocation) continue;
      if (_Combinator.byName(current.methodName.name) == null) continue;

      return current;
    }

    return null;
  }

  /// The fpdart wrapper name to build with, taken from what the call returns.
  ///
  /// Read from the *return* type rather than the receiver so a `map` that
  /// changes the value type still names the right constructor. Resolved by
  /// type, so an unrelated class with a `map` method is never expanded.
  String? _wrapperNameOf(MethodInvocation invocation) {
    final type = invocation.staticType;
    if (type is! InterfaceType) return null;
    if (!anyFpdartChecker.isAssignableFromType(type)) return null;

    return type.element.name;
  }
}
