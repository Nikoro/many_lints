import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_inverted_boolean_checks.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidInvertedBooleanChecksTest),
  );
}

@reflectiveTest
class AvoidInvertedBooleanChecksTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidInvertedBooleanChecks();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_negatedGreaterThan() async {
    await assertDiagnostics(
      r'''
bool check(int a, int b) {
  return !(a > b);
}
''',
      [lint(36, 8)],
    );
  }

  Future<void> test_negatedLessThan() async {
    await assertDiagnostics(
      r'''
bool check(int a, int b) {
  return !(a < b);
}
''',
      [lint(36, 8)],
    );
  }

  Future<void> test_negatedGreaterOrEqual() async {
    await assertDiagnostics(
      r'''
bool check(int a, int b) {
  return !(a >= b);
}
''',
      [lint(36, 9)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_directComparison() async {
    await assertNoDiagnostics(r'''
bool check(int a, int b) {
  return a <= b;
}
''');
  }

  Future<void> test_negatedEqualityIsOtherRule() async {
    await assertNoDiagnostics(r'''
bool check(int a, int b) {
  return !(a == b);
}
''');
  }

  Future<void> test_doubleOperandsNotReported() async {
    await assertNoDiagnostics(r'''
bool check(double a, double b) {
  return !(a > b);
}
''');
  }

  Future<void> test_customTypeOperandsNotReported() async {
    await assertNoDiagnostics(r'''
class Version {
  bool operator >(Version other) => true;
  bool operator <=(Version other) => true;
}

bool check(Version a, Version b) {
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
}
