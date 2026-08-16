// ignore_for_file: unused_element
// ignore_for_file: many_lints/prefer_void_callback

// format_test_name
//
// Detects a test description that does not match the configured pattern.
//
// A test name is read far more often than it is written — in CI output, in a
// failure report, in a bisect log — and it is read without the code beside it.
//
// This rule reports nothing until configured:
//
//   format_test_name:
//     pattern: 'should .*'

void test(String description, void Function() body) {}
void group(String description, void Function() body) {}

void main() {
  // ❌ Bad
  // LINT: 'works fine' does not match 'should .*'
  test('works fine', () {});

  // ✅ Good
  test('should load a user from the cache', () {});

  // Edge case: a `group` names a SUBJECT rather than an expectation, so it is
  // exempt by default. Set `check_groups: true` to include groups too.
  group('UserRepository', () {});

  // Edge case: a non-literal description cannot be read without evaluating it,
  // so a parameterised test is never reported.
  const subject = 'the cache';
  test('$subject works', () {});
}
