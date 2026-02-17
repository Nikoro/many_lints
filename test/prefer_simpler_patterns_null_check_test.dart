import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_simpler_patterns_null_check.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferSimplerPatternsNullCheckTest),
  );
}

@reflectiveTest
class PreferSimplerPatternsNullCheckTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferSimplerPatternsNullCheck();
    super.setUp();
  }

  Future<void> test_nullCheckWithUntypedBinding() async {
    // `!= null && final field` should be `final field?`
    await assertDiagnostics(
      r'''
void f(String? s) {
  if (s case != null && final field) {}
}
''',
      [lint(33, 22)],
    );
  }

  Future<void> test_nullCheckWithTypedBinding() async {
    // `!= null && final String field` should be `final String field`
    await assertDiagnostics(
      r'''
void f(String? s) {
  if (s case != null && final String field) {}
}
''',
      [lint(33, 29)],
    );
  }

  Future<void> test_nullCheckWithVarBinding() async {
    // `!= null && var field` should also trigger
    await assertDiagnostics(
      r'''
void f(String? s) {
  if (s case != null && var field) {}
}
''',
      [lint(33, 20)],
    );
  }

  Future<void> test_noLint_simplerNullablePattern() async {
    // Already using the simpler `final field?` syntax
    await assertNoDiagnostics(r'''
void f(String? s) {
  if (s case final field?) {}
}
''');
  }

  Future<void> test_noLint_typedBindingOnly() async {
    // Just a typed binding without null check is fine
    await assertNoDiagnostics(r'''
void f(String? s) {
  if (s case final String field) {}
}
''');
  }

  Future<void> test_noLint_relationalPatternOnly() async {
    // Just `!= null` without binding is fine
    await assertNoDiagnostics(r'''
void f(String? s) {
  if (s case != null) {}
}
''');
  }

  Future<void> test_noLint_logicalAndWithoutNullCheck() async {
    // Logical and pattern without null check on left side
    await assertNoDiagnostics(r'''
void f(int value) {
  if (value case > 0 && < 10) {}
}
''');
  }

  Future<void> test_noLint_nullCheckOrPattern() async {
    // Logical or pattern with null check is fine
    await assertNoDiagnostics(r'''
void f(String? s) {
  if (s case != null || '') {}
}
''');
  }

  Future<void> test_nullCheckWithTypedBinding_int() async {
    // Different type annotation
    await assertDiagnostics(
      r'''
void f(int? n) {
  if (n case != null && final int value) {}
}
''',
      [lint(30, 26)],
    );
  }
}
