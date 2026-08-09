import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_correct_json_casts.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferCorrectJsonCastsTest),
  );
}

@reflectiveTest
class PreferCorrectJsonCastsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferCorrectJsonCasts();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_castToNonNullableString() async {
    await assertDiagnostics(
      r'''
String f(Map<String, dynamic> json) => json['name'] as String;
''',
      [lint(39, 22)],
    );
  }

  Future<void> test_castToNonNullableInt() async {
    await assertDiagnostics(
      r'''
int f(Map<String, dynamic> json) => json['age'] as int;
''',
      [lint(36, 18)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_nullableCastIsFine() async {
    await assertNoDiagnostics(r'''
String? f(Map<String, dynamic> json) => json['name'] as String?;
''');
  }

  Future<void> test_nullableCastWithFallback() async {
    await assertNoDiagnostics(r'''
String f(Map<String, dynamic> json) => json['name'] as String? ?? '';
''');
  }

  Future<void> test_typedMapIsIgnored() async {
    await assertNoDiagnostics(r'''
String f(Map<String, String> json) => json['name'] as String;
''');
  }

  // ---- Edge cases ----

  Future<void> test_castToObjectIsIgnored() async {
    await assertNoDiagnostics(r'''
Object f(Map<String, dynamic> json) => json['name'] as Object;
''');
  }

  Future<void> test_nonIndexExpressionIsIgnored() async {
    await assertNoDiagnostics(r'''
num f(Map<String, dynamic> json) => json.length as num;
''');
  }

  Future<void> test_nonMapTargetIsIgnored() async {
    await assertNoDiagnostics(r'''
String f(List<dynamic> values) => values[0] as String;
''');
  }
}
