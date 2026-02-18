// ignore_for_file: unused_local_variable

// prefer_expect_later
//
// Warns when a Future is passed to expect() instead of expectLater().
// Not awaiting a Future in expect() can lead to tests that silently pass
// because the assertion completes before the asynchronous operation finishes.

void expect(dynamic actual, dynamic matcher) {}

Future<void> expectLater(dynamic actual, dynamic matcher) async {}

const completion = 1;

// ❌ Bad: Using expect() with a Future
Future<void> bad() async {
  // LINT: Future passed to expect — should use expectLater
  expect(Future.value(1), completion);

  // LINT: Future variable passed to expect
  final future = Future.value(42);
  expect(future, completion);

  // LINT: Async function result passed to expect
  expect(fetchData(), completion);
}

// ✅ Good: Using expectLater() with a Future
Future<void> good() async {
  // Correct: expectLater with await
  await expectLater(Future.value(1), completion);

  // Correct: expectLater with a Future variable
  final future = Future.value(42);
  await expectLater(future, completion);

  // Correct: expect with non-Future values
  expect(42, completion);
  expect('hello', completion);
  expect([1, 2, 3], completion);
}

Future<int> fetchData() async => 42;
