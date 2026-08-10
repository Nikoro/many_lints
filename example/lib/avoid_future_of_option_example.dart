// ignore_for_file: unused_element, unused_local_variable

// avoid_future_of_option
//
// The `Option` half of the same argument: `Future<Option<T>>` is what
// `TaskOption` already is, minus the composition and the laziness.

import 'package:fpdart/fpdart.dart';

class _User {
  const _User(this.name);
  final String name;
}

Future<_User?> _lookup(String id) async => const _User('ada');

// ❌ Bad: callers must await before they can chain
// LINT: return TaskOption<_User> instead
Future<Option<_User>> badFutureOfOption(String id) async =>
    Option.fromNullable(await _lookup(id));

// ❌ Bad: same shape on a class method
class BadCache {
  // LINT: return TaskOption<_User> instead
  Future<Option<_User>> find(String id) async =>
      Option.fromNullable(await _lookup(id));
}

// ✅ Good: composable and lazy
TaskOption<_User> goodTaskOption(String id) =>
    TaskOption(() async => Option.fromNullable(await _lookup(id)));

// ✅ Good: a synchronous Option is a different shape entirely
Option<_User> goodPlainOption() => Option.of(const _User('ada'));

// ✅ Edge case: a stream of results is not one TaskOption
Stream<Option<_User>> goodStream() async* {
  yield Option.of(const _User('ada'));
}
