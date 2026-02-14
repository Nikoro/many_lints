import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_collection_equality_checks.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidCollectionEqualityChecksTest),
  );
}

@reflectiveTest
class AvoidCollectionEqualityChecksTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidCollectionEqualityChecks();
    super.setUp();
  }

  // ── Positive cases (should trigger lint) ──────────────────────────

  Future<void> test_listEquality() async {
    await assertDiagnostics(
      r'''
void f(List<int> a, List<int> b) {
  a == b;
}
''',
      [lint(37, 6)],
    );
  }

  Future<void> test_listInequality() async {
    await assertDiagnostics(
      r'''
void f(List<int> a, List<int> b) {
  a != b;
}
''',
      [lint(37, 6)],
    );
  }

  Future<void> test_setEquality() async {
    await assertDiagnostics(
      r'''
void f(Set<int> a, Set<int> b) {
  a == b;
}
''',
      [lint(35, 6)],
    );
  }

  Future<void> test_mapEquality() async {
    await assertDiagnostics(
      r'''
void f(Map<String, int> a, Map<String, int> b) {
  a == b;
}
''',
      [lint(51, 6)],
    );
  }

  Future<void> test_iterableEquality() async {
    await assertDiagnostics(
      r'''
void f(Iterable<int> a, Iterable<int> b) {
  a == b;
}
''',
      [lint(45, 6)],
    );
  }

  Future<void> test_listComparedToNull_noLint() async {
    // Comparing to null is fine — null check, not collection equality.
    await assertNoDiagnostics(r'''
void f(List<int>? a) {
  a == null;
}
''');
  }

  Future<void> test_mutableAndConst() async {
    // One side is mutable — should trigger.
    await assertDiagnostics(
      r'''
void f(List<int> a) {
  a == const [1, 2];
}
''',
      [lint(24, 17)],
    );
  }

  // ── Negative cases (should NOT trigger lint) ──────────────────────

  Future<void> test_bothConst() async {
    await assertNoDiagnostics(r'''
void f() {
  const [1] == const [1];
}
''');
  }

  Future<void> test_nonCollectionEquality() async {
    await assertNoDiagnostics(r'''
void f(int a, int b) {
  a == b;
}
''');
  }

  Future<void> test_stringEquality() async {
    await assertNoDiagnostics(r'''
void f(String a, String b) {
  a == b;
}
''');
  }

  Future<void> test_collectionComparedToNullLiteral() async {
    await assertNoDiagnostics(r'''
void f(List<int>? a) {
  a != null;
}
''');
  }
}
