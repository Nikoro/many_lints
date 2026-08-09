import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_unused_after_null_check.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidUnusedAfterNullCheckTest),
  );
}

@reflectiveTest
class AvoidUnusedAfterNullCheckTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnusedAfterNullCheck();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_checkedButWrongVariableUsed() async {
    await assertDiagnostics(
      r'''
void f(String? a, String b) {
  if (a != null) {
    print(b);
  }
}
''',
      [lint(36, 9)],
    );
  }

  Future<void> test_equalsNullElseBranch() async {
    await assertDiagnostics(
      r'''
void f(String? a, String b) {
  if (a == null) {
    print('missing');
  } else {
    print(b);
  }
}
''',
      [lint(36, 9)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_checkedVariableUsed() async {
    await assertNoDiagnostics(r'''
void f(String? a) {
  if (a != null) {
    print(a);
  }
}
''');
  }

  Future<void> test_equalsNullElseUsesVariable() async {
    await assertNoDiagnostics(r'''
void f(String? a) {
  if (a == null) {
    print('missing');
  } else {
    print(a);
  }
}
''');
  }

  Future<void> test_usedNestedDeeper() async {
    await assertNoDiagnostics(r'''
void f(String? a, bool flag) {
  if (a != null) {
    if (flag) {
      print(a);
    }
  }
}
''');
  }

  Future<void> test_nonNullCheckConditionIgnored() async {
    await assertNoDiagnostics(r'''
void f(bool flag, String b) {
  if (flag) {
    print(b);
  }
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_fieldIsIgnored() async {
    await assertNoDiagnostics(r'''
class Holder {
  String? value;

  void f(String other) {
    if (value != null) {
      print(other);
    }
  }
}
''');
  }

  Future<void> test_equalsNullWithNoElseIsIgnored() async {
    await assertNoDiagnostics(r'''
void f(String? a) {
  if (a == null) {
    print('missing');
  }
}
''');
  }

  Future<void> test_nullOnLeftSide() async {
    await assertDiagnostics(
      r'''
void f(String? a, String b) {
  if (null != a) {
    print(b);
  }
}
''',
      [lint(36, 9)],
    );
  }
}
