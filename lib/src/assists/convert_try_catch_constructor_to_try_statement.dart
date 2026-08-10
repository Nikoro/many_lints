import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

import '../ast_node_analysis.dart';
import '../fpdart_type_checkers.dart';

/// Which fpdart wrapper a `tryCatch` belongs to, and how it unfolds.
enum _Wrapper {
  either(success: 'right', failure: 'left'),
  taskEither(success: 'right', failure: 'left'),
  option(success: 'some', failure: 'none');

  const _Wrapper({required this.success, required this.failure});

  /// The top-level constructor function for a success value.
  ///
  /// fpdart ships lowercase shorthands (`right`, `some`) alongside the
  /// `Either.right` / `Option.of` factories. They are used here because they
  /// read as the plain constructors they are and infer both type arguments
  /// from the enclosing return type.
  final String success;

  /// The top-level constructor function for the failure value.
  final String failure;
}

/// Expands `Either.tryCatch` / `TaskEither.tryCatch` / `Option.tryCatch` into
/// an explicit `try`/`catch`.
///
/// **`Either.tryCatch`**:
///
/// ```dart
/// Either<Failure, User> parseUser(String json) => Either.tryCatch(
///       () => User.fromJson(jsonDecode(json)),
///       (error, stackTrace) => Failure.parse(error, stackTrace),
///     );
/// ```
///
/// becomes
///
/// ```dart
/// Either<Failure, User> parseUser(String json) {
///   try {
///     return right(User.fromJson(jsonDecode(json)));
///   } catch (error, stackTrace) {
///     return left(Failure.parse(error, stackTrace));
///   }
/// }
/// ```
///
/// **`TaskEither.tryCatch`** keeps the laziness that makes it a `TaskEither`
/// at all, so the `try` moves inside the `TaskEither(() async { ... })`
/// constructor rather than into the enclosing function's body:
///
/// ```dart
/// TaskEither<Failure, User> fetchUser(String id) => TaskEither(() async {
///       try {
///         return right(await api.getUser(id));
///       } catch (error, stackTrace) {
///         return left(Failure.from(error));
///       }
///     });
/// ```
///
/// **`Option.tryCatch`** has no `onError` — there is nothing to carry — so the
/// catch clause takes no parameters and yields `none()`.
///
/// ## Why only a whole function body converts
///
/// `try` is a *statement*, so it needs somewhere to live. When the `tryCatch`
/// is the entire body of a function the expression body becomes a block and
/// the statement has a home. Mid-pipeline — `Either.tryCatch(...).flatMap(f)`
/// — there is no such place, and the only expression-level equivalent is an
/// immediately-invoked closure, which is worse than what it replaces. The
/// assist is therefore offered only on a whole body and declines otherwise.
///
/// ## Why an assist rather than a quick fix
///
/// `tryCatch` is the better form nearly always: it is shorter, it cannot
/// forget to wrap a branch, and it composes. Expanding it is a situational
/// choice — usually to add logging, retries, or per-exception-type handling
/// that the single `onError` callback cannot express — so it belongs on a
/// deliberate gesture and not on a diagnostic.
class ConvertTryCatchConstructorToTryStatement
    extends ResolvedCorrectionProducer {
  static const _assistKind = AssistKind(
    'many_lints.assist.convertTryCatchConstructorToTryStatement',
    30,
    "Expand 'tryCatch' into 'try'/'catch'",
  );

  ConvertTryCatchConstructorToTryStatement({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => _assistKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final invocation = _enclosingTryCatch();
    if (invocation == null) return;

    final wrapper = _wrapperOf(invocation);
    if (wrapper == null) return;

    // `try` is a statement, so the call has to be a whole function body for
    // there to be anywhere to put it.
    final body = _bodyExpandedBy(invocation);
    if (body == null) return;

    final arguments = invocation.argumentList.arguments;
    final expected = wrapper == _Wrapper.option ? 1 : 2;
    if (arguments.length != expected) return;

    final run = _callbackAt(arguments, 0);
    if (run == null) return;

    // `run` is called with no arguments; one that declares parameters is not
    // the shape `tryCatch` accepts and would not compile.
    if (_parameterCountOf(run) != 0) return;

    final success = maybeGetSingleReturnExpression(run.body);
    if (success == null) return;

    final catchClause = wrapper == _Wrapper.option
        ? _optionCatchClause(wrapper)
        : _errorCatchClause(arguments, wrapper);
    if (catchClause == null) return;

    // `TaskEither.tryCatch` takes a `Future<R> Function()`, so the value the
    // callback produces has to be awaited before it can be wrapped in an
    // `Either`. The other two are synchronous.
    final awaitKeyword = wrapper == _Wrapper.taskEither ? 'await ' : '';
    final returned = '${wrapper.success}($awaitKeyword${success.toSource()})';

    final indent = _leadingWhitespaceOf(body.offset);
    final replacement = wrapper == _Wrapper.taskEither
        ? _taskEitherBody(
            returned,
            catchClause,
            indent,
            isBlock: body is BlockFunctionBody,
          )
        : _blockBody(returned, catchClause, indent);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        SourceRange(body.offset, body.length),
        replacement,
      );
    });
  }

  /// The expanded body for `Either` and `Option`: the enclosing function grows
  /// a block containing the `try`.
  String _blockBody(String returned, _CatchClause clause, String indent) =>
      '{\n'
      '$indent  try {\n'
      '$indent    return $returned;\n'
      '$indent  } ${clause.source} {\n'
      '$indent    return ${clause.result};\n'
      '$indent  }\n'
      '$indent}';

  /// The expanded body for `TaskEither`.
  ///
  /// The `try` moves *inside* a `TaskEither(() async { ... })` rather than into
  /// the enclosing function, because hoisting it out would run the effect
  /// eagerly and defeat the point of the type.
  ///
  /// The whole body is rewritten, so it has to be spelled the way the body it
  /// replaces was: `=> ...;` for an expression body, `{ return ...; }` for a
  /// block one.
  String _taskEitherBody(
    String returned,
    _CatchClause clause,
    String indent, {
    required bool isBlock,
  }) {
    final task =
        'TaskEither(() async {\n'
        '$indent      try {\n'
        '$indent        return $returned;\n'
        '$indent      } ${clause.source} {\n'
        '$indent        return ${clause.result};\n'
        '$indent      }\n'
        '$indent    })';

    return isBlock ? '{\n$indent  return $task;\n$indent}' : '=> $task;';
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

  /// The `tryCatch` invocation the cursor sits in.
  InstanceCreationExpression? _enclosingTryCatch() {
    for (AstNode? current = node; current != null; current = current.parent) {
      if (current is InstanceCreationExpression &&
          current.constructorName.name?.name == 'tryCatch') {
        return current;
      }
    }

    return null;
  }

  /// Which fpdart wrapper [invocation] constructs, or null when it is not an
  /// fpdart `tryCatch` at all.
  ///
  /// Resolving the constructor's own class rather than reading the written
  /// name keeps a user-defined `tryCatch` from matching, and keeps an aliased
  /// import from failing to.
  _Wrapper? _wrapperOf(InstanceCreationExpression invocation) {
    final element = invocation.constructorName.element;
    if (element == null) return null;

    final owner = element.enclosingElement;
    if (eitherChecker.isExactly(owner)) return _Wrapper.either;
    if (taskEitherChecker.isExactly(owner)) return _Wrapper.taskEither;
    if (optionChecker.isExactly(owner)) return _Wrapper.option;

    return null;
  }

  /// The function body [invocation] makes up in its entirety, or null when it
  /// is only part of a larger expression.
  FunctionBody? _bodyExpandedBy(InstanceCreationExpression invocation) {
    final parent = invocation.parent;

    // `=> Either.tryCatch(...)`
    if (parent is ExpressionFunctionBody &&
        parent.expression == invocation &&
        !parent.isAsynchronous &&
        !parent.isGenerator) {
      return parent;
    }

    // `{ return Either.tryCatch(...); }` — a block body whose only statement
    // is the return, which is the same shape written the long way.
    if (parent is ReturnStatement && parent.expression == invocation) {
      final block = parent.parent;
      if (block is Block && block.statements.length == 1) {
        final body = block.parent;
        if (body is BlockFunctionBody &&
            !body.isAsynchronous &&
            !body.isGenerator) {
          return body;
        }
      }
    }

    return null;
  }

  /// The callback argument at [index], if it is written inline.
  ///
  /// A tear-off (`Failure.from`) is not a [FunctionExpression], so it has no
  /// parameter names or body to move into a `catch`; those decline.
  FunctionExpression? _callbackAt(NodeList<Argument> arguments, int index) {
    final argument = arguments[index].argumentExpression.unParenthesized;
    return argument is FunctionExpression ? argument : null;
  }

  /// How many parameters [callback] declares.
  int _parameterCountOf(FunctionExpression callback) =>
      callback.parameters?.parameters.length ?? 0;

  /// The `catch (...)` clause for `Option`, which carries no error value.
  _CatchClause? _optionCatchClause(_Wrapper wrapper) =>
      _CatchClause(source: 'catch (_)', result: '${wrapper.failure}()');

  /// The `catch (...)` clause for `Either` / `TaskEither`, built from the
  /// `onError` callback's own parameter names and body.
  _CatchClause? _errorCatchClause(
    NodeList<Argument> arguments,
    _Wrapper wrapper,
  ) {
    final onError = _callbackAt(arguments, 1);
    if (onError == null) return null;

    final parameters = onError.parameters?.parameters;
    if (parameters == null || parameters.isEmpty || parameters.length > 2) {
      return null;
    }

    final failure = maybeGetSingleReturnExpression(onError.body);
    if (failure == null) return null;

    final errorName = parameters.first.name?.lexeme;
    if (errorName == null) return null;

    final stackName = parameters.length == 2
        ? parameters[1].name?.lexeme
        : null;
    if (parameters.length == 2 && stackName == null) return null;

    // Declaring a stack trace the body never reads earns an immediate
    // `unused_catch_stack` warning — the expanded code would arrive with a new
    // lint on it. `onError` has no such rule, so this is not a case the
    // original could hit.
    final keepsStack =
        stackName != null && _referencesName(onError.body, stackName);

    final catchSource = keepsStack
        ? 'catch ($errorName, $stackName)'
        : 'catch ($errorName)';

    return _CatchClause(
      source: catchSource,
      result: '${wrapper.failure}(${failure.toSource()})',
    );
  }

  /// Whether [body] mentions [name].
  bool _referencesName(FunctionBody body, String name) {
    final finder = _IdentifierFinder(name);
    body.accept(finder);
    return finder.found;
  }
}

/// A generated `catch` clause and the value its body returns.
class _CatchClause {
  /// The clause itself, e.g. `catch (error, stackTrace)`.
  final String source;

  /// The wrapped failure the clause returns, e.g. `left(Failure.from(error))`.
  final String result;

  const _CatchClause({required this.source, required this.result});
}

/// Reports whether a subtree references a given name.
class _IdentifierFinder extends RecursiveAstVisitor<void> {
  final String name;
  bool found = false;

  _IdentifierFinder(this.name);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == name) found = true;
    super.visitSimpleIdentifier(node);
  }
}
