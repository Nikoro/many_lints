import 'package:many_lints/src/rules/avoid_skipped_tests.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidSkippedTestsTest));
}

@reflectiveTest
class AvoidSkippedTestsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidSkippedTests();
    super.setUp();
  }

  Future<void> test_skip_true_on_test() async {
    await assertDiagnostics(
      r'''
void test(String description, void Function() body, {Object? skip}) {}

void main() {
  test('parses a malformed manifest', () {}, skip: true);
}
''',
      [lint(131, 10)],
    );
  }

  Future<void> test_skip_reason_on_test() async {
    await assertDiagnostics(
      r'''
void test(String description, void Function() body, {Object? skip}) {}

void main() {
  test('handles a timeout', () {}, skip: 'flaky on CI');
}
''',
      [lint(121, 19)],
    );
  }

  Future<void> test_skip_on_group() async {
    await assertDiagnostics(
      r'''
void group(String description, void Function() body, {Object? skip}) {}

void main() {
  group('upload', () {}, skip: true);
}
''',
      [lint(112, 10)],
    );
  }

  Future<void> test_skip_on_setUp() async {
    await assertDiagnostics(
      r'''
void setUp(void Function() body, {Object? skip}) {}

void main() {
  setUp(() {}, skip: true);
}
''',
      [lint(82, 10)],
    );
  }

  Future<void> test_skip_annotation_on_library() async {
    await assertDiagnostics(
      r'''
@Skip('needs a real device')
library;

class Skip {
  const Skip(String reason);
}
''',
      [lint(0, 28)],
    );
  }

  Future<void> test_no_skip() async {
    await assertNoDiagnostics(r'''
void test(String description, void Function() body, {Object? skip}) {}

void main() {
  test('parses a malformed manifest', () {});
}
''');
  }

  Future<void> test_skip_false_is_a_no_op() async {
    await assertNoDiagnostics(r'''
void test(String description, void Function() body, {Object? skip}) {}

void main() {
  test('parses a malformed manifest', () {}, skip: false);
}
''');
  }

  Future<void> test_skip_on_unrelated_method_with_a_target() async {
    await assertNoDiagnostics(r'''
class Harness {
  void test(String description, {bool skip = false}) {}
}

void main() {
  Harness().test('not a test declaration', skip: true);
}
''');
  }

  Future<void> test_skip_annotation_not_on_library() async {
    await assertNoDiagnostics(r'''
class Skip {
  const Skip(String reason);
}

@Skip('this is not a library-level skip')
class Thing {}
''');
  }
}
