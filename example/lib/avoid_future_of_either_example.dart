// ignore_for_file: unused_element, unused_local_variable

// avoid_future_of_either
//
// `Future<Either<L, R>>` is correct, but it is what `TaskEither` already is
// with the composition removed: a caller has to await before it can chain, and
// the future has started running before anyone holds it.

import 'package:fpdart/fpdart.dart';

class _User {
  const _User(this.name);
  final String name;
}

Future<_User> _fetch(String id) async => const _User('ada');

// ❌ Bad: callers must await before they can chain
// LINT: return TaskEither<String, _User> instead
Future<Either<String, _User>> badFutureOfEither(String id) async =>
    Either.of(await _fetch(id));

// ❌ Bad: same shape on a class method
class BadRepository {
  // LINT: return TaskEither<String, _User> instead
  Future<Either<String, _User>> load(String id) async =>
      Either.of(await _fetch(id));
}

// ✅ Good: composable and lazy
TaskEither<String, _User> goodTaskEither(String id) =>
    TaskEither.tryCatch(() => _fetch(id), (error, stackTrace) => '$error');

// ✅ Good: a synchronous Either is a different shape entirely
Either<String, _User> goodPlainEither() => Either.of(const _User('ada'));

// ✅ Edge case: FutureOr may complete synchronously, so it is not reported
Future<Either<String, _User>>? goodNullableIsNotReported;

// ✅ Edge case: a stream of results is not one TaskEither
Stream<Either<String, _User>> goodStream() async* {
  yield Either.of(const _User('ada'));
}
