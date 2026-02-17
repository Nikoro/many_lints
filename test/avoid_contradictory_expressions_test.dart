import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_contradictory_expressions.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidContradictoryExpressionsTest),
  );
}

@reflectiveTest
class AvoidContradictoryExpressionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidContradictoryExpressions();
    super.setUp();
  }

  // ── Positive cases (should trigger lint) ──────────────────────────

  Future<void> test_equalEqual_differentIntLiterals() async {
    await assertDiagnostics(
      r'''
void f(int x) {
  x == 3 && x == 4;
}
''',
      [lint(18, 16)],
    );
  }

  Future<void> test_equalEqual_differentStringLiterals() async {
    await assertDiagnostics(
      r'''
void f(String x) {
  x == 'a' && x == 'b';
}
''',
      [lint(21, 20)],
    );
  }

  Future<void> test_equalAndNotEqual_sameOperands() async {
    await assertDiagnostics(
      r'''
void f(int x) {
  x == 2 && x != 2;
}
''',
      [lint(18, 16)],
    );
  }

  Future<void> test_lessThanAndGreaterThan_sameOperands() async {
    await assertDiagnostics(
      r'''
void f(int x) {
  x < 4 && x > 4;
}
''',
      [lint(18, 14)],
    );
  }

  Future<void> test_equalAndLessThan_sameOperands() async {
    await assertDiagnostics(
      r'''
void f(int x) {
  x == 4 && x < 4;
}
''',
      [lint(18, 15)],
    );
  }

  Future<void> test_equalAndGreaterThan_sameOperands() async {
    await assertDiagnostics(
      r'''
void f(int x) {
  x == 4 && x > 4;
}
''',
      [lint(18, 15)],
    );
  }

  Future<void> test_variableComparedToVariable_contradictory() async {
    await assertDiagnostics(
      r'''
void f(int x, int y) {
  x == y && x != y;
}
''',
      [lint(25, 16)],
    );
  }

  Future<void> test_chainedAnd_contradictionInChain() async {
    await assertDiagnostics(
      r'''
void f(int a, bool b) {
  a == 1 && b && a == 3;
}
''',
      [lint(26, 21)],
    );
  }

  Future<void> test_equalEqual_differentBoolLiterals() async {
    await assertDiagnostics(
      r'''
void f(bool x) {
  x == true && x == false;
}
''',
      [lint(19, 23)],
    );
  }

  // ── Negative cases (should NOT trigger lint) ──────────────────────

  Future<void> test_orOperator_noLint() async {
    await assertNoDiagnostics(r'''
void f(int x) {
  x == 3 || x == 4;
}
''');
  }

  Future<void> test_consistentRange_noLint() async {
    await assertNoDiagnostics(r'''
void f(int x) {
  x < 4 && x > 2;
}
''');
  }

  Future<void> test_singleComparison_noLint() async {
    await assertNoDiagnostics(r'''
void f(int x) {
  x == 2;
}
''');
  }

  Future<void> test_sameEqualityTwice_noLint() async {
    // Redundant but not contradictory.
    await assertNoDiagnostics(r'''
void f(int x) {
  x == 3 && x == 3;
}
''');
  }

  Future<void> test_differentVariables_noLint() async {
    await assertNoDiagnostics(r'''
void f(int x, int y) {
  x == 3 && y == 4;
}
''');
  }

  Future<void> test_nonComparisonOperator_noLint() async {
    await assertNoDiagnostics(r'''
void f(int x) {
  x + 3 > 0 && x - 1 < 10;
}
''');
  }

  Future<void> test_equalEqual_differentVariableValues_noLint() async {
    // x == a && x == b where a, b are variables — not provably different.
    await assertNoDiagnostics(r'''
void f(int x, int a, int b) {
  x == a && x == b;
}
''');
  }
}
