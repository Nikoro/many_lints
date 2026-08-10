import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../future_of_fpdart_rule.dart';
import '../type_checker.dart';

/// Warns when a function returns `Future<Either<L, R>>` instead of
/// `TaskEither<L, R>`.
///
/// `Future<Either<L, R>>` is correct — unlike `Either<L, Future<R>>`, which
/// `avoid_either_of_future` reports as a genuine bug — but it is the same
/// thing `TaskEither` already is, with the composition thrown away. A caller
/// cannot `flatMap` it without awaiting first, so every chain has to leave the
/// fpdart world and come back:
///
/// ```dart
/// final either = await repo.getUser(id);
/// final result = await either.match(
///   (failure) async => left(failure),
///   (user) => repo.loadOrders(user.id),
/// );
/// ```
///
/// The same pipeline in `TaskEither` is one expression, because the type
/// carries both the asynchrony and the failure channel.
///
/// The eagerness matters too: a `Future` starts running when it is created, so
/// a `Future<Either>` cannot be retried, delayed, or built up and run later. A
/// `TaskEither` describes the work instead of performing it.
///
/// **Bad:**
/// ```dart
/// Future<Either<Failure, User>> getUser(String id) async {
///   return right(await api.get(id));
/// }
/// ```
///
/// **Good:**
/// ```dart
/// TaskEither<Failure, User> getUser(String id) => TaskEither.tryCatch(
///       () => api.get(id),
///       (error, stackTrace) => Failure.from(error),
///     );
/// ```
///
/// ## Options
///
/// - `ignore_private`: when `true`, a private function is not reported. The
///   default is `false`: a `Future<Either>` is awkward to consume wherever it
///   appears, private or not.
class AvoidFutureOfEither extends FutureOfFpdartRule {
  static const LintCode code = LintCode(
    'avoid_future_of_either',
    "Returning 'Future<Either>' instead of '{0}'.",
    correctionMessage:
        "Return '{0}' so the pipeline stays composable and lazy, and callers "
        "can chain with 'flatMap' instead of awaiting first.",
  );

  AvoidFutureOfEither()
    : super(
        name: 'avoid_future_of_either',
        description:
            'Warns when a function returns Future<Either> rather than the '
            'equivalent TaskEither.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  TypeChecker get wrappedChecker => eitherChecker;

  @override
  String get replacementType => 'TaskEither';
}
