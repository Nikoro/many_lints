// ignore_for_file: many_lints/avoid_commented_out_code

// prefer_correct_test_file_name
//
// Detects a file under `test/` that declares tests but is not named
// `*_test.dart`.
//
// `package:test` only runs files matching `*_test.dart`. A file named
// `user_repository_tests.dart` still compiles, still passes analysis, and is
// silently never executed — the worst failure mode a test can have, because
// the suite stays green by not running.

// ❌ Bad
//
//   test/user_repository_tests.dart     → LINT: never runs (plural `tests`)
//   test/test_user_repository.dart      → LINT: never runs (prefix, not suffix)
//
//   void main() {
//     test('should load a user', () {});
//   }

// ✅ Good
//
//   test/user_repository_test.dart
//
//   void main() {
//     test('should load a user', () {});
//   }

// Edge case: a file under `test/` that declares NO tests is not a test file.
// Fixtures, robots and builders live there legitimately and are never
// reported — the rule looks for a `test(...)`, `testWidgets(...)` or
// `group(...)` call before saying anything.
//
//   test/support/user_builder.dart      → silent, declares no tests
//
// This example sits in `lib/`, so the rule does not apply to it: the paths
// above are what it demonstrates.
class UserBuilder {}
