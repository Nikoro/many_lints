// ignore_for_file: unused_element
// ignore_for_file: many_lints/prefer_type_over_var

// avoid_redundant_async
//
// Warns when a function is marked async but never awaits, which wraps the
// result in an extra Future and defers the body for nothing.

class Config {}

final _cached = Config();

// ❌ Bad: nothing is awaited
// LINT: `async` adds a wrapping Future and defers the body
Future<Config> badLoad() async {
  return _cached;
}

// ❌ Bad: same with an expression body
// LINT: the future is already there to return
Future<Config> badExpression() async => _cached;

// ✅ Good: the future is returned directly
Future<Config> goodLoad() {
  return _cached as Future<Config>;
}

// ✅ Good: it actually awaits
Future<Config> goodAwaiting(Future<Config> pending) async {
  return await pending;
}

// ✅ Edge case: `await for` suspends just as `await` does.
Future<int> goodAwaitFor(Stream<int> values) async {
  var total = 0;
  await for (final value in values) {
    total += value;
  }
  return total;
}

// ✅ Edge case: `async*` is what makes this a stream generator.
Stream<int> goodGenerator() async* {
  yield 1;
}

// ✅ Edge case: with nothing to return, dropping `async` would turn
// `Future<void>` into `void` — a signature change, not a cleanup.
Future<void> goodVoid() async {
  _record();
}

void _record() {}
