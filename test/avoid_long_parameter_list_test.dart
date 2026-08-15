import 'package:many_lints/src/rules/avoid_long_parameter_list.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidLongParameterListTest),
  );
}

@reflectiveTest
class AvoidLongParameterListTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidLongParameterList();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_fivePositionalParameters() async {
    await assertDiagnostics(
      r'''
void f(int a, int b, int c, int d, int e) {}
''',
      [lint(5, 1)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_fourPositionalIsWithinBudget() async {
    await assertNoDiagnostics(r'''
void f(int a, int b, int c, int d) {}
''');
  }

  Future<void> test_namedParametersScaleFurther() async {
    // Named parameters are labelled at the call site and do not depend on
    // order, so a widget constructor with several is not the problem.
    await assertNoDiagnostics(r'''
void f({
  int? a,
  int? b,
  int? c,
  int? d,
  int? e,
  int? f,
  int? g,
}) {}
''');
  }

  Future<void> test_noParameters() async {
    await assertNoDiagnostics(r'''
void f() {}
''');
  }

  Future<void> test_overrideCannotChangeItsSignature() async {
    // Only the base declaration is reported; an override has to match it.
    await assertDiagnostics(
      r'''
class Base {
  void f(int a, int b, int c, int d, int e) {}
}

class A extends Base {
  @override
  void f(int a, int b, int c, int d, int e) {}
}
''',
      [lint(20, 1)],
    );
  }
}
