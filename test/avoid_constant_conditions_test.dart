import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_constant_conditions.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidConstantConditionsTest),
  );
}

@reflectiveTest
class AvoidConstantConditionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidConstantConditions();
    super.setUp();
  }

  // ── Positive cases (should trigger lint) ──────────────────────────

  Future<void> test_twoIntLiterals() async {
    await assertDiagnostics(
      r'''
void f() {
  10 == 11;
}
''',
      [lint(13, 8)],
    );
  }

  Future<void> test_twoStringLiterals() async {
    await assertDiagnostics(
      r'''
void f() {
  'a' == 'b';
}
''',
      [lint(13, 10)],
    );
  }

  Future<void> test_twoBoolLiterals() async {
    await assertDiagnostics(
      r'''
void f() {
  true == false;
}
''',
      [lint(13, 13)],
    );
  }

  Future<void> test_constVariableBothSides() async {
    await assertDiagnostics(
      r'''
const a = 10;
const b = 20;
void f() {
  a == b;
}
''',
      [lint(41, 6)],
    );
  }

  Future<void> test_staticConstField() async {
    await assertDiagnostics(
      r'''
abstract final class Config {
  static const value = '1';
}
void f() {
  Config.value == '1';
}
''',
      [lint(73, 19)],
    );
  }

  Future<void> test_lessThanWithLiterals() async {
    await assertDiagnostics(
      r'''
void f() {
  10 < 20;
}
''',
      [lint(13, 7)],
    );
  }

  Future<void> test_greaterThanWithLiterals() async {
    await assertDiagnostics(
      r'''
void f() {
  10 > 20;
}
''',
      [lint(13, 7)],
    );
  }

  Future<void> test_notEqualWithLiterals() async {
    await assertDiagnostics(
      r'''
void f() {
  1 != 2;
}
''',
      [lint(13, 6)],
    );
  }

  Future<void> test_negativeNumberLiteral() async {
    await assertDiagnostics(
      r'''
void f() {
  -1 == -2;
}
''',
      [lint(13, 8)],
    );
  }

  // ── Negative cases (should NOT trigger lint) ──────────────────────

  Future<void> test_variableAndLiteral_noLint() async {
    await assertNoDiagnostics(r'''
void f(int x) {
  x == 10;
}
''');
  }

  Future<void> test_twoVariables_noLint() async {
    await assertNoDiagnostics(r'''
void f(int x, int y) {
  x == y;
}
''');
  }

  Future<void> test_variableAndConstField_noLint() async {
    await assertNoDiagnostics(r'''
const limit = 10;
void f(int x) {
  x < limit;
}
''');
  }

  Future<void> test_nonConstFinalVariable_noLint() async {
    await assertNoDiagnostics(r'''
void f(int x) {
  final y = x + 1;
  y == 10;
}
''');
  }

  Future<void> test_methodCallResult_noLint() async {
    await assertNoDiagnostics(r'''
void f(List<int> list) {
  list.length == 0;
}
''');
  }

  Future<void> test_additionOperator_noLint() async {
    // Non-comparison operators should not trigger.
    await assertNoDiagnostics(r'''
void f() {
  1 + 2;
}
''');
  }
}
