// ignore_for_file: many_lints/avoid_focused_tests, many_lints/prefer_void_callback

// avoid_skipped_tests
//
// Warns when a test, group or library is switched off in place.
// A skipped test still counts as a test: the runner reports it and exits zero.

void test(String description, void Function() body, {Object? skip}) {}
void group(String description, void Function() body, {Object? skip}) {}
void setUp(void Function() body, {Object? skip}) {}

// ❌ Bad: tests that will never run
void bad() {
  // LINT: a skip with no reason at all
  test('parses a malformed manifest', () {}, skip: true);

  // LINT: a reason makes the skip readable, not acceptable
  test('handles a timeout', () {}, skip: 'flaky on CI');

  // LINT: a whole group, silently
  group('upload', () {}, skip: true);

  // LINT: a lifecycle hook takes the same argument
  setUp(() {}, skip: true);
}

// ✅ Good: the test runs, or it is gone
void good() {
  test('parses a malformed manifest', () {});

  group('upload', () {});

  setUp(() {});
}

// Edge cases: not reported.
void edgeCases() {
  // `skip: false` is a no-op, and occasionally a deliberate placeholder.
  test('parses a malformed manifest', () {}, skip: false);

  // A method named `test` on someone's own object is not a test declaration.
  Harness().test('not a test declaration', skip: true);
}

class Harness {
  void test(String description, {bool skip = false}) {}
}
