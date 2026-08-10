import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../ast_node_analysis.dart';
import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';
import '../type_checker.dart';

/// Class name suffixes that mark a boundary where failures are expected.
const _defaultSuffixes = {'Repository', 'Service', 'DataSource', 'Client'};

/// Warns when a boundary class handles failure with `try`/`catch` instead of
/// returning a `TaskEither`.
///
/// A repository's failures are part of its contract, not exceptions: callers
/// have to handle "the network was down" every time, and a signature that says
/// `Future<User>` promises otherwise. The `try`/`catch` inside then has nowhere
/// good to go — it either swallows the error and returns a fallback, or
/// rethrows and leaves the caller exactly where it started.
///
/// `TaskEither<Failure, T>` puts the failure in the type, so the compiler
/// enforces what the docstring used to ask for.
///
/// Only classes whose name ends in a configured suffix are checked, since this
/// is a statement about architectural boundaries rather than about `try`/`catch`
/// in general.
///
/// **Bad:**
/// ```dart
/// class UserRepository {
///   Future<User> load(String id) async {
///     try {
///       return await _api.getUser(id);
///     } catch (e) {
///       throw UserLoadException(e);
///     }
///   }
/// }
/// ```
///
/// **Good:**
/// ```dart
/// class UserRepository {
///   TaskEither<Failure, User> load(String id) => TaskEither.tryCatch(
///         () => _api.getUser(id),
///         (error, stackTrace) => Failure.from(error),
///       );
/// }
/// ```
///
/// ## Options
///
/// - `class_suffixes` / `additional_class_suffixes`: replace or extend the set
///   of class name suffixes that mark a boundary.
/// - `ignore_private`: when `true` (the default), a private method is not
///   reported — it is an implementation detail of the class rather than part
///   of the contract callers see.
class PreferTaskEitherOverTryCatch extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_task_either_over_try_catch',
    "'{0}' handles failure with 'try'/'catch' instead of returning a "
        "'TaskEither'.",
    correctionMessage:
        "Return 'TaskEither<Failure, T>' built with 'TaskEither.tryCatch', so "
        'the failure is part of the signature.',
  );

  PreferTaskEitherOverTryCatch()
    : super(
        name: 'prefer_task_either_over_try_catch',
        description:
            'Warns when a repository or service method handles failure with '
            'try/catch rather than returning a TaskEither.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferTaskEitherOverTryCatch rule;

  _Visitor(this.rule);

  static const _futureChecker = TypeChecker.fromUrl('dart:async#Future');

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final name = node.name.lexeme;

    if (rule.config.boolOption('ignore_private', defaultValue: true) &&
        name.startsWith('_')) {
      return;
    }

    final enclosing = enclosingClassDeclaration(node);
    if (enclosing == null) return;
    if (!_isBoundaryClass(enclosing.namePart.typeName.lexeme)) return;

    // Only async work: a synchronous failable method is `Either`'s job, and
    // suggesting `TaskEither` there would be wrong.
    final returnType = node.returnType?.type;
    if (returnType == null) return;
    if (!_futureChecker.isAssignableFromType(returnType)) return;

    // A method already returning an fpdart type is doing the right thing, even
    // when it is wrapped in a Future.
    if (anyFpdartChecker.isAssignableFromType(returnType)) return;

    final body = node.body;
    if (!_containsTryCatch(body)) return;

    rule.reportAtToken(node.name, arguments: [name]);
  }

  /// Whether [className] ends in one of the configured boundary suffixes.
  bool _isBoundaryClass(String className) {
    final suffixes = rule.config.nameSetOption(
      'class_suffixes',
      defaultValue: _defaultSuffixes,
    );

    return suffixes.any(className.endsWith);
  }

  /// Whether [body] contains a `try` statement of its own.
  bool _containsTryCatch(FunctionBody body) {
    final finder = _TryFinder();
    body.accept(finder);
    return finder.found;
  }
}

/// Finds a `try` statement, not descending into closures.
///
/// A `try` inside a callback belongs to that callback's own control flow —
/// often a genuinely best-effort adapter — and is not what the method's
/// signature is promising.
class _TryFinder extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Deliberately does not descend.
  }

  @override
  void visitTryStatement(TryStatement node) {
    // Only a `catch` makes this failure handling; a bare `try`/`finally` is
    // cleanup, which `TaskEither` does not replace.
    if (node.catchClauses.isNotEmpty) found = true;
    super.visitTryStatement(node);
  }
}
