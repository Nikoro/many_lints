import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_empty_spread.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidEmptySpreadTest));
}

@reflectiveTest
class AvoidEmptySpreadTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidEmptySpread();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_emptyListSpread() async {
    await assertDiagnostics(
      r'''
List<int> build() {
  return [1, ...[], 2];
}
''',
      [lint(33, 5)],
    );
  }

  Future<void> test_emptySetSpread() async {
    await assertDiagnostics(
      r'''
Set<int> build() {
  return {1, ...{}, 2};
}
''',
      [lint(32, 5)],
    );
  }

  Future<void> test_emptyTypedListSpread() async {
    await assertDiagnostics(
      r'''
List<int> build() {
  return [1, ...<int>[]];
}
''',
      [lint(33, 10)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_nonEmptySpread() async {
    await assertNoDiagnostics(r'''
List<int> build() {
  return [1, ...[2, 3]];
}
''');
  }

  Future<void> test_spreadOfVariable() async {
    await assertNoDiagnostics(r'''
List<int> build(List<int> other) {
  return [1, ...other];
}
''');
  }

  Future<void> test_nullAwareSpreadOfVariable() async {
    await assertNoDiagnostics(r'''
List<int> build(List<int>? other) {
  return [1, ...?other];
}
''');
  }

  Future<void> test_emptyLiteralWithoutSpread() async {
    await assertNoDiagnostics(r'''
List<List<int>> build() {
  return [[], []];
}
''');
  }
}
