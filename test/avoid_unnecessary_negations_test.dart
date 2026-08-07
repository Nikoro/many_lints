import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_unnecessary_negations.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidUnnecessaryNegationsTest),
  );
}

@reflectiveTest
class AvoidUnnecessaryNegationsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryNegations();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_doubleNegation() async {
    await assertDiagnostics(
      r'''
bool check(bool flag) {
  return !!flag;
}
''',
      [lint(33, 6)],
    );
  }

  Future<void> test_negatedInequality() async {
    await assertDiagnostics(
      r'''
bool check(int a, int b) {
  return !(a != b);
}
''',
      [lint(36, 9)],
    );
  }

  Future<void> test_doubleNegationWithParentheses() async {
    await assertDiagnostics(
      r'''
bool check(bool flag) {
  return !(!flag);
}
''',
      [lint(33, 8)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_singleNegation() async {
    await assertNoDiagnostics(r'''
bool check(bool flag) {
  return !flag;
}
''');
  }

  Future<void> test_negatedEquality() async {
    await assertNoDiagnostics(r'''
bool check(int a, int b) {
  return !(a == b);
}
''');
  }

  Future<void> test_negatedComparison() async {
    await assertNoDiagnostics(r'''
bool check(int a, int b) {
  return !(a > b);
}
''');
  }

  Future<void> test_negatedConjunction() async {
    await assertNoDiagnostics(r'''
bool check(bool a, bool b) {
  return !(a && b);
}
''');
  }

  Future<void> test_negatedMethodCall() async {
    await assertNoDiagnostics(r'''
bool check(List<int> items) {
  return !items.isEmpty;
}
''');
  }

  // ---- Negated boolean literals ----

  Future<void> test_negatedTrue() async {
    await assertDiagnostics(
      r'''
bool check() {
  return !true;
}
''',
      [lint(24, 5)],
    );
  }

  Future<void> test_negatedFalse() async {
    await assertDiagnostics(
      r'''
bool check() {
  return !false;
}
''',
      [lint(24, 6)],
    );
  }

  // ---- Negations on both sides of a comparison ----

  Future<void> test_negationsAroundEquality() async {
    await assertDiagnostics(
      r'''
bool check(bool a, bool b) {
  return !a == !b;
}
''',
      [lint(38, 8)],
    );
  }

  Future<void> test_negationsAroundInequality() async {
    await assertDiagnostics(
      r'''
bool check(bool a, bool b) {
  return !a != !b;
}
''',
      [lint(38, 8)],
    );
  }

  Future<void> test_singleNegationInComparison() async {
    await assertNoDiagnostics(r'''
bool check(bool a, bool b) {
  return !a == b;
}
''');
  }
}
