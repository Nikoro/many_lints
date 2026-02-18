import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_contains.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferContainsTest));
}

@reflectiveTest
class PreferContainsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferContains();
    super.setUp();
  }

  // --- Positive cases (should trigger lint) ---

  Future<void> test_indexOfEqNegativeOne() async {
    await assertDiagnostics(
      r'''
void f(List<int> list) {
  list.indexOf(1) == -1;
}
''',
      [lint(27, 21)],
    );
  }

  Future<void> test_indexOfNeNegativeOne() async {
    await assertDiagnostics(
      r'''
void f(List<int> list) {
  list.indexOf(1) != -1;
}
''',
      [lint(27, 21)],
    );
  }

  Future<void> test_negativeOneEqIndexOf() async {
    await assertDiagnostics(
      r'''
void f(List<int> list) {
  -1 == list.indexOf(1);
}
''',
      [lint(27, 21)],
    );
  }

  Future<void> test_negativeOneNeIndexOf() async {
    await assertDiagnostics(
      r'''
void f(List<int> list) {
  -1 != list.indexOf(1);
}
''',
      [lint(27, 21)],
    );
  }

  Future<void> test_indexOfOnString() async {
    await assertDiagnostics(
      r'''
void f(String s) {
  s.indexOf('a') == -1;
}
''',
      [lint(21, 20)],
    );
  }

  Future<void> test_indexOfInIfCondition() async {
    await assertDiagnostics(
      r'''
void f(List<int> list) {
  if (list.indexOf(1) != -1) {}
}
''',
      [lint(31, 21)],
    );
  }

  // --- Negative cases (should NOT trigger lint) ---

  Future<void> test_indexOfComparedToZero_noLint() async {
    await assertNoDiagnostics(r'''
void f(List<int> list) {
  list.indexOf(1) == 0;
}
''');
  }

  Future<void> test_indexOfComparedToPositive_noLint() async {
    await assertNoDiagnostics(r'''
void f(List<int> list) {
  list.indexOf(1) == 2;
}
''');
  }

  Future<void> test_containsCall_noLint() async {
    await assertNoDiagnostics(r'''
void f(List<int> list) {
  list.contains(1);
}
''');
  }

  Future<void> test_indexOfUsedAsValue_noLint() async {
    await assertNoDiagnostics(r'''
void f(List<int> list) {
  final idx = list.indexOf(1);
}
''');
  }

  Future<void> test_indexOfGreaterThan_noLint() async {
    await assertNoDiagnostics(r'''
void f(List<int> list) {
  list.indexOf(1) > -1;
}
''');
  }
}
