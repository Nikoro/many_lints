import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../future_of_fpdart_rule.dart';
import '../type_checker.dart';

/// Warns when a function returns `Future<Option<T>>` instead of
/// `TaskOption<T>`.
///
/// The `Option` counterpart of `avoid_future_of_either`, and the same
/// argument: `Future<Option<T>>` is correct but throws away composition. A
/// caller has to await before it can `flatMap`, so every chain leaves the
/// fpdart world and comes back, and the `Future` has already started running
/// by the time anyone holds it.
///
/// `TaskOption<T>` is the type that already means "async computation that may
/// find nothing", and it stays lazy until `.run()`.
///
/// **Bad:**
/// ```dart
/// Future<Option<User>> findUser(String id) async {
///   return Option.fromNullable(await cache.get(id));
/// }
/// ```
///
/// **Good:**
/// ```dart
/// TaskOption<User> findUser(String id) =>
///     TaskOption(() async => Option.fromNullable(await cache.get(id)));
/// ```
///
/// ## Options
///
/// - `ignore_private`: when `true`, a private function is not reported. The
///   default is `false`: a `Future<Option>` is awkward to consume wherever it
///   appears, private or not.
class AvoidFutureOfOption extends FutureOfFpdartRule {
  static const LintCode code = LintCode(
    'avoid_future_of_option',
    "Returning 'Future<Option>' instead of '{0}'.",
    correctionMessage:
        "Return '{0}' so the pipeline stays composable and lazy, and callers "
        "can chain with 'flatMap' instead of awaiting first.",
  );

  AvoidFutureOfOption()
    : super(
        name: 'avoid_future_of_option',
        description:
            'Warns when a function returns Future<Option> rather than the '
            'equivalent TaskOption.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  TypeChecker get wrappedChecker => optionChecker;

  @override
  String get replacementType => 'TaskOption';
}
