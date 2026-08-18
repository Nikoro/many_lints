import 'package:many_lints/src/rules/avoid_empty_catch.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidEmptyCatchTest));
}

@reflectiveTest
class AvoidEmptyCatchTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidEmptyCatch();
    super.setUp();
  }

  Future<void> test_empty_catch() async {
    await assertDiagnostics(
      r'''
void f() {
  try {
    print('x');
  } catch (e) {}
}
''',
      [lint(39, 12)],
    );
  }

  /// The SDK's `empty_catches` permits this shape; this rule is a superset.
  Future<void> test_empty_catch_with_wildcard() async {
    await assertDiagnostics(
      r'''
void f() {
  try {
    print('x');
  } catch (_) {}
}
''',
      [lint(39, 12)],
    );
  }

  /// Also permitted by `empty_catches`, and also reported here by default.
  Future<void> test_comment_only_body() async {
    await assertDiagnostics(
      r'''
void f() {
  try {
    print('x');
  } catch (e) {
    // Ignored, really.
  }
}
''',
      [lint(39, 39)],
    );
  }

  Future<void> test_empty_on_clause() async {
    await assertDiagnostics(
      r'''
void f() {
  try {
    print('x');
  } on FormatException {}
}
''',
      [lint(39, 21)],
    );
  }

  Future<void> test_body_logs() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
    print('x');
  } catch (e) {
    print(e);
  }
}
''');
  }

  Future<void> test_body_rethrows() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
    print('x');
  } catch (e) {
    rethrow;
  }
}
''');
  }

  Future<void> test_empty_try_body_is_not_a_catch() async {
    await assertNoDiagnostics(r'''
void f() {
  try {} catch (e) {
    print(e);
  }
}
''');
  }
}
