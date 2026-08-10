// ignore_for_file: unused_element, unused_local_variable

// avoid_either_of_future
//
// `Either` and `Option` are synchronous. Putting a `Future` inside one starts
// the work but leaves it outside the error channel: a rejection becomes an
// unhandled async error, and callers still see a `Right`.

import 'package:fpdart/fpdart.dart';

class _League {
  const _League(this.name);
  final String name;
}

Future<_League> _save(String name) async => _League(name);

Either<String, String> _validate(String name) => Either.of(name);

// ❌ Bad: the future escapes the error channel
// LINT: convert with toTaskEither() and chain there
Either<String, Future<_League>> badWrittenType(String name) =>
    _validate(name).map(_save);

// ❌ Bad: same nesting, never written down
void badMappedFuture(Either<String, String> either) {
  // LINT: convert with toTaskEither() and chain there
  final result = either.map((name) => _save(name));
}

// ❌ Bad: Option has the same problem
// LINT: convert with toTaskOption() and chain there
Option<Future<_League>> badOption(Option<String> option) => option.map(_save);

// ✅ Good: enter the async world once, then keep chaining
TaskEither<String, _League> goodConverted(String name) =>
    _validate(name).toTaskEither().flatMap(
      (valid) => TaskEither.tryCatch(
        () => _save(valid),
        (error, stackTrace) => error.toString(),
      ),
    );

// ✅ Good: a Future belongs inside the async wrapper
TaskEither<String, _League> goodTaskEither(String name) => TaskEither.tryCatch(
  () => _save(name),
  (error, stackTrace) => error.toString(),
);

// ✅ Good: a synchronous map is exactly what Either is for
void goodSyncMap(Either<String, String> either) {
  final result = either.map((name) => name.toUpperCase());
}

// ✅ Good: Iterable.map returning futures is ordinary Dart
void goodIterableMap(List<String> names) {
  final futures = names.map(_save);
}
