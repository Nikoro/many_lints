import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_expect_later.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferExpectLaterTest));
}

@reflectiveTest
class PreferExpectLaterTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferExpectLater();

    newPackage('test_api').addFile('lib/test_api.dart', r'''
void expect(dynamic actual, dynamic matcher) {}
Future<void> expectLater(dynamic actual, dynamic matcher) async {}

const completion = 1;
''');

    super.setUp();
  }

  // ── Positive cases: should trigger the lint ──────────────────────────

  Future<void> test_expectWithFutureValue() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(Future.value(1), completion);
}
''',
      [lint(55, 6)],
    );
  }

  Future<void> test_expectWithFutureDelayed() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(Future.delayed(Duration.zero), completion);
}
''',
      [lint(55, 6)],
    );
  }

  Future<void> test_expectWithFutureVariable() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

void f() {
  final future = Future.value(42);
  expect(future, completion);
}
''',
      [lint(90, 6)],
    );
  }

  Future<void> test_expectWithAsyncFunction() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

Future<int> getValue() async => 42;

void f() {
  expect(getValue(), completion);
}
''',
      [lint(92, 6)],
    );
  }

  // ── Negative cases: should NOT trigger the lint ──────────────────────

  Future<void> test_expectWithNonFutureValue() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(42, completion);
}
''');
  }

  Future<void> test_expectWithStringValue() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  expect('hello', completion);
}
''');
  }

  Future<void> test_expectLaterAlreadyUsed() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() async {
  await expectLater(Future.value(1), completion);
}
''');
  }

  Future<void> test_expectWithDynamic() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f(dynamic value) {
  expect(value, completion);
}
''');
  }

  Future<void> test_expectWithListValue() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  expect([1, 2, 3], completion);
}
''');
  }

  Future<void> test_nonExpectCall_noLint() async {
    await assertNoDiagnostics(r'''
void check(dynamic actual, dynamic matcher) {}

void f() {
  check(Future.value(1), 'matcher');
}
''');
  }
}
