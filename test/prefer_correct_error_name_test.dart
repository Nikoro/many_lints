import 'package:many_lints/src/rules/prefer_correct_error_name.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferCorrectErrorNameTest),
  );
}

@reflectiveTest
class PreferCorrectErrorNameTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferCorrectErrorName();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_exceptionWithoutSuffix() async {
    await assertDiagnostics(
      r'''
class NotFound implements Exception {}
''',
      [lint(6, 8)],
    );
  }

  Future<void> test_errorWithoutSuffix() async {
    await assertDiagnostics(
      r'''
class BadState extends Error {}
''',
      [lint(6, 8)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_exceptionWithSuffix() async {
    await assertNoDiagnostics(r'''
class NotFoundException implements Exception {}
''');
  }

  Future<void> test_errorWithSuffix() async {
    await assertNoDiagnostics(r'''
class BadStateError extends Error {}
''');
  }

  Future<void> test_ordinaryClassIsNotConsidered() async {
    await assertNoDiagnostics(r'''
class Widget {}
''');
  }

  // ---- Edge cases ----

  Future<void> test_indirectExceptionIsStillAnException() async {
    await assertDiagnostics(
      r'''
class BaseException implements Exception {}
class NotFound extends BaseException {}
''',
      [lint(50, 8)],
    );
  }

  Future<void> test_errorWinsOverException() async {
    // A class that is both should be named for the stricter reading: an Error
    // is a bug the caller must not catch.
    await assertNoDiagnostics(r'''
class WeirdError extends Error implements Exception {}
''');
  }
}
