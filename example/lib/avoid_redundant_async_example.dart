// ignore_for_file: unused_element
// ignore_for_file: many_lints/prefer_type_over_var

// avoid_redundant_async
//
// Warns when a function is marked async without awaiting or throwing and all
// return paths already produce compatible Future values.

class Config {}

final Future<Config> _pending = Future.value(Config());

// ❌ Bad: nothing is awaited
// LINT: this Future can be returned directly
Future<Config> badLoad() async {
  return _pending;
}

// ❌ Bad: same with an expression body
// LINT: the future is already there to return
Future<Config> badExpression() async => _pending;

// ✅ Good: the future is returned directly
Future<Config> goodLoad() {
  return _pending;
}

// ✅ Good: `async` is required to wrap a raw value in a Future.
Future<Config> goodRawValue() async => Config();

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
