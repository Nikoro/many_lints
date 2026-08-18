import 'package:many_lints/src/rules/avoid_focused_tests.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidFocusedTestsTest));
}

@reflectiveTest
class AvoidFocusedTestsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidFocusedTests();
    super.setUp();
  }

  Future<void> test_solo_on_test() async {
    await assertDiagnostics(
      r'''
void test(String description, void Function() body, {bool solo = false}) {}

void main() {
  test('the one I am debugging', () {}, solo: true);
}
''',
      [lint(131, 10)],
    );
  }

  Future<void> test_solo_on_group() async {
    await assertDiagnostics(
      r'''
void group(String description, void Function() body, {bool solo = false}) {}

void main() {
  group('upload', () {}, solo: true);
}
''',
      [lint(117, 10)],
    );
  }

  Future<void> test_no_solo() async {
    await assertNoDiagnostics(r'''
void test(String description, void Function() body, {bool solo = false}) {}

void main() {
  test('the one I am debugging', () {});
}
''');
  }

  Future<void> test_solo_false_is_a_no_op() async {
    await assertNoDiagnostics(r'''
void test(String description, void Function() body, {bool solo = false}) {}

void main() {
  test('the one I am debugging', () {}, solo: false);
}
''');
  }

  Future<void> test_solo_on_setUp_is_not_a_focus() async {
    await assertNoDiagnostics(r'''
void setUp(void Function() body, {bool solo = false}) {}

void main() {
  setUp(() {}, solo: true);
}
''');
  }

  Future<void> test_solo_on_unrelated_method_with_a_target() async {
    await assertNoDiagnostics(r'''
class Harness {
  void test(String description, {bool solo = false}) {}
}

void main() {
  Harness().test('not a test declaration', solo: true);
}
''');
  }
}
