// ignore_for_file: unused_element, unused_local_variable, avoid_print

// avoid_catch_error
//
// Warns about Future.catchError. Its handler is an untyped Function, so a
// wrong signature only fails at runtime, and the `test` argument can silently
// leave an error unhandled.

import 'dart:async';

Future<int> _fetch() async => 1;

// ❌ Bad: the handler's signature is never checked by the analyzer
Future<int> badSimple() {
  // LINT: use await with try/catch instead
  return _fetch().catchError((Object err) => 0);
}

// ❌ Bad: `test` returning false leaves the error unhandled, though it reads
// as though it was caught
Future<int> badWithTest() {
  // LINT: the filtering belongs in an `on` clause
  return _fetch().catchError(
    (Object err) => 0,
    test: (Object e) => e is TimeoutException,
  );
}

// ❌ Bad: at the end of a chain
Future<int> badInChain() {
  // LINT: still an untyped handler
  return _fetch().then((v) => v * 2).catchError((Object err) => 0);
}

// ✅ Good: the catch clause is checked at compile time
Future<int> goodSimple() async {
  try {
    return await _fetch();
  } catch (err, st) {
    print('$err $st');
    return 0;
  }
}

// ✅ Good: filtering by type is an `on` clause
Future<int> goodTyped() async {
  try {
    return await _fetch();
  } on TimeoutException catch (err) {
    print(err);
    return 0;
  }
}

// ✅ Edge case: an unrelated `catchError` on a non-Future type is not reported
class _Task {
  void catchError(void Function(Object) handler) {}
}

void unrelatedCatchError(_Task task) {
  task.catchError((err) {});
}

// ✅ Edge case: a tear-off has no call site to rewrite, so it is left alone
void tearOff() {
  final handler = _fetch().catchError;
  print(handler);
}
