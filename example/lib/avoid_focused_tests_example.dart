// ignore_for_file: many_lints/prefer_void_callback

// avoid_focused_tests
//
// Warns when a test or group is focused with `solo:`.
// A focused test silences every other test in the file — they are never run.

void test(String description, void Function() body, {bool solo = false}) {}
void group(String description, void Function() body, {bool solo = false}) {}
void setUp(void Function() body, {bool solo = false}) {}

// ❌ Bad: everything else in the file silently stops running
void bad() {
  // LINT: the only test in this file that now runs
  test('the one I am debugging', () {}, solo: true);

  // LINT: a whole group of siblings suppressed
  group('upload', () {}, solo: true);
}

// ✅ Good: narrow the run from the command line instead
//
//   dart test --name 'the one I am debugging'
//   dart test test/upload_test.dart
void good() {
  test('the one I am debugging', () {});

  group('upload', () {});
}

// Edge cases: not reported.
void edgeCases() {
  // The default written out suppresses nothing.
  test('the one I am debugging', () {}, solo: false);

  // A lifecycle hook has no `solo` of its own to commit.
  setUp(() {}, solo: true);

  // A method named `test` on someone's own object is not a test declaration.
  Harness().test('not a test declaration', solo: true);
}

class Harness {
  void test(String description, {bool solo = false}) {}
}
