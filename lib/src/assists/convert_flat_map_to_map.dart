import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

import '../fpdart_chain_call.dart';
import '../fpdart_type_checkers.dart';

/// Converts `flatMap((v) => TaskEither.right(f(v)))` to `map(f)`.
///
/// A callback that only re-wraps its result is doing `map`'s job with `map`'s
/// name spelled longer. `flatMap` exists for a callback that returns a new
/// *effect*; when the effect is a constant `right`/`of`, the wrapping is
/// ceremony.
///
/// ```dart
/// pipeline.flatMap((v) => TaskEither.right(transform(v)))
/// ```
///
/// becomes
///
/// ```dart
/// pipeline.map(transform)
/// ```
///
/// ## Declines when the body branches
///
/// A conditional returning `left` on one side is a genuine `flatMap`: it can
/// fail, and `map` cannot. Only an unconditional re-wrap converts, which is
/// why the body must be exactly one wrapping constructor call.
class ConvertFlatMapToMap extends ResolvedCorrectionProducer {
  static const _assistKind = AssistKind(
    'many_lints.assist.convertFlatMapToMap',
    30,
    "Convert to 'map'",
  );

  /// Constructors that wrap a plain value in a successful wrapper.
  ///
  /// `left` is deliberately absent: it is a failure, and a callback producing
  /// one is exactly the `flatMap` this assist must not touch.
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

  /// The value inside a wrapping constructor call, or `null` when [body] is
  /// not one.
  ///
  /// Both spellings are accepted: the static `TaskEither.right(x)` and the
  /// top-level `right(x)` fpdart also exports.
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

  /// The sole positional argument of [arguments], or `null`.
  Expression? _singleArgumentOf(ArgumentList arguments) {
    final positional = arguments.arguments;
    if (positional.length != 1) return null;

    final argument = positional.single;
    return argument is NamedArgument ? null : argument.argumentExpression;
  }

  /// Whether [expression] evaluates to an fpdart wrapper.
  ///
  /// Resolved by type rather than by the constructor name, so an unrelated
  /// class with an `of` constructor is never converted.
  bool _isFpdartType(Expression expression) {
    final type = expression.staticType;
    return type != null && anyFpdartChecker.isAssignableFromType(type);
  }

  /// The argument `map` should receive.
  ///
  /// A body that is exactly `f(v)` — one call taking the callback's parameter
  /// and nothing else — becomes the tear-off `f`. Anything else keeps the
  /// closure, since the expression may use the parameter more than once or in
  /// a position no tear-off can express.
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
