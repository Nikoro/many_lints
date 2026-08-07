import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_immediate_return.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferImmediateReturnTest));
}

@reflectiveTest
class PreferImmediateReturnTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferImmediateReturn();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_finalVariableThenReturn() async {
    await assertDiagnostics(
      r'''
int compute(int a) {
  final result = a * 2;
  return result;
}
''',
      [lint(23, 21)],
    );
  }

  Future<void> test_varVariableThenReturn() async {
    await assertDiagnostics(
      r'''
int compute(int a) {
  var result = a * 2;
  return result;
}
''',
      [lint(23, 19)],
    );
  }

  Future<void> test_typedVariableThenReturn() async {
    await assertDiagnostics(
      r'''
String describe(int a) {
  final String label = 'value: $a';
  return label;
}
''',
      [lint(27, 33)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_variableUsedTwice() async {
    await assertNoDiagnostics(r'''
int compute(int a) {
  final result = a * 2;
  print(result);
  return result;
}
''');
  }

  Future<void> test_variableUsedInInitializerOfAnother() async {
    await assertNoDiagnostics(r'''
int compute(int a) {
  final doubled = a * 2;
  final result = doubled + 1;
  return doubled;
}
''');
  }

  Future<void> test_directReturn() async {
    await assertNoDiagnostics(r'''
int compute(int a) {
  return a * 2;
}
''');
  }

  Future<void> test_returnsVariableDeclaredEarlier() async {
    await assertNoDiagnostics(r'''
int compute(int a, int b) {
  final first = a * 2;
  final second = b * 2;
  return first;
}
''');
  }

  Future<void> test_multipleVariablesInOneDeclaration() async {
    await assertNoDiagnostics(r'''
int compute(int a) {
  var first = a, second = a * 2;
  return second;
}
''');
  }

  Future<void> test_uninitializedVariable() async {
    await assertNoDiagnostics(r'''
int compute(int a) {
  int result;
  result = a * 2;
  return result;
}
''');
  }

  Future<void> test_statementBetweenDeclarationAndReturn() async {
    await assertNoDiagnostics(r'''
int compute(int a) {
  final result = a * 2;
  print('done');
  return result;
}
''');
  }

  Future<void> test_returnsField() async {
    await assertNoDiagnostics(r'''
class Holder {
  int result = 0;

  int compute(int a) {
    final other = a * 2;
    return result;
  }
}
''');
  }
}
