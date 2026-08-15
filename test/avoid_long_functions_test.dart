import 'package:many_lints/src/rules/avoid_long_functions.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidLongFunctionsTest));
}

@reflectiveTest
class AvoidLongFunctionsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidLongFunctions();
    super.setUp();
  }

  // ---- Negative cases (should NOT trigger lint) ----
  //
  // The default budget is 50 lines, which no hand-written fixture here
  // reaches; the threshold itself is exercised by the config tests in
  // rule_options_test.dart, which can set `max_lines`.

  Future<void> test_shortFunction() async {
    await assertNoDiagnostics(r'''
void f() {
  final v1 = 1;
  final v2 = 2;
  final v3 = 3;
  final v4 = 4;
  final v5 = 5;
  final v6 = 6;
  final v7 = 7;
}
''');
  }

  Future<void> test_expressionBodyIsNeverTooLong() async {
    await assertNoDiagnostics(r'''
int f() => 1;
''');
  }

  Future<void> test_abstractMethodHasNoBody() async {
    await assertNoDiagnostics(r'''
abstract class A {
  void f();
}
''');
  }

  Future<void> test_aFunctionUnderTheDefaultBudget() async {
    await assertNoDiagnostics(r'''
void f() {
  final v1 = 1;
  final v2 = 2;
  final v3 = 3;
  final v4 = 4;
  final v5 = 5;
  final v6 = 6;
  final v7 = 7;
  final v8 = 8;
  final v9 = 9;
  final v10 = 10;
  final v11 = 11;
}
''');
  }
}
