import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/prefer_simpler_patterns_null_check.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferSimplerPatternsNullCheckTest),
  );
}

@reflectiveTest
class PreferSimplerPatternsNullCheckTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferSimplerPatternsNullCheck();
    super.setUp();
  }

  Future<void> test_nullCheckWithUntypedBinding() async {
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
    await assertNoDiagnostics(r'''
void f(String? s) {
  if (s case final field?) {}
}
''');
  }

  Future<void> test_noLint_typedBindingOnly() async {
    await assertNoDiagnostics(r'''
void f(String? s) {
  if (s case final String field) {}
}
''');
  }

  Future<void> test_noLint_relationalPatternOnly() async {
    await assertNoDiagnostics(r'''
void f(String? s) {
  if (s case != null) {}
}
''');
  }

  Future<void> test_noLint_logicalAndWithoutNullCheck() async {
    await assertNoDiagnostics(r'''
void f(int value) {
  if (value case > 0 && < 10) {}
}
''');
  }

  Future<void> test_noLint_nullCheckOrPattern() async {
    await assertNoDiagnostics(r'''
void f(String? s) {
  if (s case != null || '') {}
}
''');
  }

  Future<void> test_nullCheckWithTypedBinding_int() async {
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
