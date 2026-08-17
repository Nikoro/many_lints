// ignore_for_file: unused_element, unused_local_variable

// prefer_unit_over_void
//
// `void` is not a value in Dart, so an fpdart type parameterised with it stops
// composing: `flatMap` has nothing to bind, and callers fall back to unwrapping
// to `null` and re-deriving success from that.

import 'package:fpdart/fpdart.dart';

class _User {
  const _User(this.name);
  final String name;
}

Future<void> _persist(_User user) async {}

// ❌ Bad: the success channel carries nothing a pipeline can use
// LINT: use Unit rather than void
TaskEither<String, void> badSave(_User user) => TaskEither.tryCatch(
  () => _persist(user),
  (error, stackTrace) => error.toString(),
);

// ❌ Bad: same for the other wrappers
// LINT: use Unit rather than void
Option<void> badOption() => const None();

// ✅ Good: Unit is a real value, so the result stays chainable
TaskEither<String, Unit> goodSave(_User user) => TaskEither.tryCatch(() async {
  await _persist(user);
  return unit;
}, (error, stackTrace) => error.toString());

// ✅ Good: and it composes with the next step
TaskEither<String, String> goodChained(_User user) =>
    goodSave(user).map((_) => 'saved');

// ✅ Good: a plain Dart void return is unaffected — this rule is only about
// fpdart type arguments
void goodPlainVoid() {}

abstract class _Repository {
  // LINT: use Unit rather than void — the interface is where the fix belongs
  TaskEither<String, void> save(_User user);
}

class _RepositoryImpl implements _Repository {
  // ✅ Good: an @override is fixed by the supertype, so it is skipped by
  // default. Reporting it would send you to the wrong file; the interface
  // above is what has to change. Set `ignore_overrides: false` to report both.
  @override
  TaskEither<String, void> save(_User user) => TaskEither.tryCatch(
    () => _persist(user),
    (error, stackTrace) => error.toString(),
  );
}
// ignore_for_file: many_lints/prefer_primary_constructors
// ignore_for_file: many_lints/prefer_returning_shorthands
