import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

import '../fpdart_type_checkers.dart';
import '../type_checker.dart';

/// The synchronous wrapper being converted, and its lazy equivalent.
enum _Wrapper {
  either(checker: eitherChecker, target: 'TaskEither', arity: 2),
  option(checker: optionChecker, target: 'TaskOption', arity: 1);

  const _Wrapper({
    required this.checker,
    required this.target,
    required this.arity,
  });

  /// Matches the synchronous wrapper this entry converts from.
  final TypeChecker checker;

  /// The fpdart type that already means "async [checker]".
  final String target;

  /// How many type arguments [target] takes — `TaskEither<L, R>` needs both,
  /// `TaskOption<R>` only the value.
  final int arity;
}

/// What the function currently returns, and therefore how its body is moved.
enum _Shape {
  /// `Future<Wrapper<...>>` — already async, so the body transplants as is.
  futureOfWrapper,

  /// A bare `Wrapper<...>` — synchronous, so the body gains an `async` it did
  /// not need before. This is the point of the conversion: an `await` becomes
  /// legal inside it.
  wrapper,
}

/// A convertible return type: which wrapper, and how it is currently spelled.
typedef _Source = ({_Wrapper wrapper, _Shape shape});

/// Converts a function returning `Future<Either<L, R>>` or `Either<L, R>`
/// into one returning `TaskEither<L, R>` — and likewise `Future<Option<T>>` /
/// `Option<T>` into `TaskOption<T>`.
///
/// **From `Future<Either<L, R>>`** — the idiomatic shape for a failable async
/// operation is `TaskEither`, which is the same thing with the laziness and
/// the combinators kept:
///
/// ```dart
/// Future<Either<Failure, User>> getUser(String id) async {
///   return right(await api.get(id));
/// }
/// ```
///
/// becomes
///
/// ```dart
/// TaskEither<Failure, User> getUser(String id) => TaskEither(() async {
///       return right(await api.get(id));
///     });
/// ```
///
/// **From `Either<L, R>`** — for when a synchronous pipeline has to grow an
/// `await` in the middle. `Either` cannot host one; `TaskEither` can, and the
/// existing `return left(...)` / `return right(...)` statements keep working
/// untouched because the body is transplanted whole:
///
/// ```dart
/// Either<Failure, User> parse(String raw) {
///   if (raw.isEmpty) return left(Failure.empty());
///   return right(User.fromJson(raw));
/// }
/// ```
///
/// becomes
///
/// ```dart
/// TaskEither<Failure, User> parse(String raw) => TaskEither(() async {
///       if (raw.isEmpty) return left(Failure.empty());
///       return right(User.fromJson(raw));
///     });
/// ```
///
/// ## Call sites are deliberately left alone
///
/// This changes a public signature, so every caller stops compiling:
/// `await getUser(id)` has to become `await getUser(id).run()`, or better,
/// the call has to be folded into the caller's own pipeline.
///
/// The assist does not touch them. `.run()` is usually the *wrong* repair —
/// it drops straight back out of the world the conversion just entered — and
/// picking the right one means looking at each caller. Rewriting files the
/// user cannot see, to a shape that is probably not what they want, is worse
/// than leaving a compile error that says exactly where to look.
///
/// ## Why an assist rather than a quick fix
///
/// For the same reason. A fix implies a diagnostic and an "apply all", and
/// neither fits a refactor whose whole cost lives outside the edited range.
class ConvertToLazyFpdartType extends ResolvedCorrectionProducer {
  static const _assistKind = AssistKind(
    'many_lints.assist.convertToLazyFpdartType',
    30,
    "Convert to '{0}'",
  );

  static const _futureChecker = TypeChecker.fromUrl('dart:async#Future');

  ConvertToLazyFpdartType({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => _assistKind;

  /// Fills the `{0}` in [_assistKind]'s message, so the lightbulb entry names
  /// the concrete target — "Convert to 'TaskEither'" — rather than a generic
  /// phrase the user has to expand mentally.
  @override
  List<String> assistArguments = const [];

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final function = _enclosingFunction();
    if (function == null) return;

    final (:returnType, :body) = function;

    // A generator yields many values; a single `TaskEither` cannot stand in
    // for a stream of them.
    if (body.isGenerator) return;

    final source = _sourceOf(returnType.type);
    if (source == null) return;

    final arguments = _typeArgumentsOf(returnType, source.wrapper);
    if (arguments == null) return;

    assistArguments = [source.wrapper.target];

    final replacement = _replacementBody(body, source);
    if (replacement == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        SourceRange(returnType.offset, returnType.length),
        '${source.wrapper.target}<$arguments>',
      );
      builder.addSimpleReplacement(
        SourceRange(body.offset, body.length),
        replacement,
      );
    });
  }

  /// The whole new function body: `=> TaskEither(<thunk>);`.
  ///
  /// `TaskEither`'s constructor wants a `Future<Either<L, R>> Function()`, so
  /// what goes inside depends on what the body already is:
  ///
  /// - a block transplants whole and gains `async`, which is what keeps every
  ///   `return left(...)` already inside it valid;
  /// - an expression body that already *is* a `Future<Either>` needs no
  ///   `async` — `() => existingCall()` is already the right thunk.
  String? _replacementBody(FunctionBody body, _Source source) {
    final indent = _leadingWhitespaceOf(body.offset);

    if (body is BlockFunctionBody) {
      // Copy the block's original text rather than `toSource()`, which
      // discards line breaks and would collapse a multi-statement body onto
      // one line. Each line is pushed one level deeper to sit inside the
      // closure it is moving into.
      final block = _reindented(body.block, indent);
      return '=> ${source.wrapper.target}(() async $block);';
    }

    if (body is ExpressionFunctionBody) {
      final expression = body.expression.toSource();

      // `=> someFutureOfEither()` is already a thunk body; wrapping it in
      // `async` would only add a redundant hop.
      final thunk =
          source.shape == _Shape.futureOfWrapper && !body.isAsynchronous
          ? '() => $expression'
          : '() async => $expression';

      return '=> ${source.wrapper.target}($thunk);';
    }

    // A native or abstract body has nothing to move.
    return null;
  }

  /// [block]'s original source with every line after the first indented one
  /// level deeper, so it reads correctly inside the closure it moves into.
  String _reindented(Block block, String indent) {
    final content = unitResult.content;
    final original = content.substring(block.offset, block.end);

    return original
        .split('\n')
        .map((line) => line.isEmpty ? line : '$indent    $line')
        .join('\n')
        // The first line follows `() async ` on the existing line, so it must
        // not carry indentation of its own.
        .trimLeft();
  }

  /// The enclosing function's declared return type and body.
  ///
  /// A function with no written return type is skipped: the replacement edits
  /// that type in place, and there would be nothing to edit.
  ({TypeAnnotation returnType, FunctionBody body})? _enclosingFunction() {
    for (AstNode? current = node; current != null; current = current.parent) {
      switch (current) {
        case MethodDeclaration(:final returnType?, :final body):
          return (returnType: returnType, body: body);
        case FunctionDeclaration(
          :final returnType?,
          functionExpression: FunctionExpression(:final body),
        ):
          return (returnType: returnType, body: body);
        // Stop at a closure boundary: its return type is its own, and the
        // enclosing function's signature is not what the cursor is on.
        case FunctionExpression():
          return null;
      }
    }

    return null;
  }

  /// Which convertible shape [type] is, or null when it is none of them.
  _Source? _sourceOf(DartType? type) {
    if (type == null) return null;

    for (final wrapper in _Wrapper.values) {
      if (wrapper.checker.isExactlyType(type)) {
        return (wrapper: wrapper, shape: _Shape.wrapper);
      }

      if (_futureChecker.isExactlyType(type) &&
          type is InterfaceType &&
          type.typeArguments.length == 1 &&
          wrapper.checker.isExactlyType(type.typeArguments.single)) {
        return (wrapper: wrapper, shape: _Shape.futureOfWrapper);
      }
    }

    return null;
  }

  /// The type arguments of the wrapper being converted, taken from the
  /// *written* type so the replacement keeps the source spelling.
  ///
  /// Reading the resolved type instead would expand type aliases and import
  /// prefixes into names that may not be in scope at this location.
  String? _typeArgumentsOf(TypeAnnotation returnType, _Wrapper wrapper) {
    if (returnType is! NamedType) return null;

    final written = returnType.typeArguments?.arguments;
    if (written == null || written.isEmpty) return null;

    // `Future<Wrapper<...>>` — unwrap one level to reach the wrapper.
    if (_futureChecker.isExactlyType(returnType.type!)) {
      final inner = written.single;
      return inner is NamedType ? _argumentsOf(inner, wrapper) : null;
    }

    return _argumentsOf(returnType, wrapper);
  }

  /// The comma-separated source of [type]'s type arguments.
  String? _argumentsOf(NamedType type, _Wrapper wrapper) {
    final arguments = type.typeArguments?.arguments;
    if (arguments == null || arguments.length != wrapper.arity) return null;

    return arguments.map((argument) => argument.toSource()).join(', ');
  }

  /// The leading whitespace of the line containing [offset].
  String _leadingWhitespaceOf(int offset) {
    final content = unitResult.content;
    if (offset <= 0) return '';

    final lineStart = content.lastIndexOf('\n', offset - 1) + 1;

    var end = lineStart;
    while (end < content.length &&
        (content[end] == ' ' || content[end] == '\t')) {
      end++;
    }

    return content.substring(lineStart, end);
  }
}
