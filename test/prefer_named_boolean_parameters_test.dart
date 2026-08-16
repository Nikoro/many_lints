import 'package:many_lints/src/rules/prefer_named_boolean_parameters.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferNamedBooleanParametersTest),
  );
}

@reflectiveTest
class PreferNamedBooleanParametersTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferNamedBooleanParameters();
    super.setUp();
  }

  Future<void> test_twoPositionalBooleans() async {
    await assertDiagnostics(
      r'''
void setVisible(bool visible, bool animate) {}
''',
      [lint(21, 7), lint(35, 7)],
    );
  }

  Future<void> test_namedBooleansAreFine() async {
    await assertNoDiagnostics(r'''
void setVisible({required bool visible, required bool animate}) {}
''');
  }

  // `setEnabled(true)` reads acceptably, so a lone positional bool is allowed
  // by default.
  Future<void> test_singlePositionalBooleanIsAllowed() async {
    await assertNoDiagnostics(r'''
void setEnabled(bool enabled) {}
''');
  }

  Future<void> test_nonBooleanPositionalsAreIgnored() async {
    await assertNoDiagnostics(r'''
void f(String a, int b) {}
''');
  }

  // An override cannot change the signature it inherits, so only the base
  // declaration is reported.
  Future<void> test_overrideIsNeverReported() async {
    await assertDiagnostics(
      r'''
class A {
  void f(bool a, bool b) {}
}

class B extends A {
  @override
  void f(bool a, bool b) {}
}
''',
      [lint(24, 1), lint(32, 1)],
    );
  }
}
