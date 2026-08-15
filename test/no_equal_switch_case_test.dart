import 'package:many_lints/src/rules/no_equal_switch_case.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(NoEqualSwitchCaseTest));
}

@reflectiveTest
class NoEqualSwitchCaseTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = NoEqualSwitchCase();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_duplicateBodyInSwitchExpression() async {
    await assertDiagnostics(
      r'''
String f(int x) => switch (x) {
  1 => 'a',
  2 => 'a',
  _ => 'b',
};
''',
      [lint(46, 8)],
    );
  }

  Future<void> test_duplicateBodyInSwitchStatement() async {
    await assertDiagnostics(
      r'''
void f(int x) {
  switch (x) {
    case 1:
      print('a');
      break;
    case 2:
      print('a');
      break;
  }
}
''',
      [lint(78, 38)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_distinctBodies() async {
    await assertNoDiagnostics(r'''
String f(int x) => switch (x) {
  1 => 'a',
  2 => 'b',
  _ => 'c',
};
''');
  }

  Future<void> test_sharedPatternsAreTheFix() async {
    await assertNoDiagnostics(r'''
String f(int x) => switch (x) {
  1 || 2 => 'a',
  _ => 'b',
};
''');
  }

  Future<void> test_emptyCasesAreFallthrough() async {
    await assertNoDiagnostics(r'''
void f(int x) {
  switch (x) {
    case 1:
    case 2:
      print('a');
      break;
  }
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_catchAllRepeatingAnEarlierBody() async {
    // The catch-all has to stay last, so it cannot be folded into an earlier
    // pattern. Sharing a body with a specific case is normal.
    await assertNoDiagnostics(r'''
int maxDayInMonth(int month) => switch (month) {
  1 || 3 || 5 || 7 || 8 || 10 || 12 => 31,
  4 || 6 || 9 || 11 => 30,
  2 => 29,
  _ => 31,
};
''');
  }

  Future<void> test_defaultRepeatingAnEarlierBody() async {
    await assertNoDiagnostics(r'''
void f(int x) {
  switch (x) {
    case 1:
      print('a');
      break;
    default:
      print('a');
  }
}
''');
  }

  Future<void> test_guardedCasesCannotBeMerged() async {
    // Each `when` belongs to its own pattern, so an `||` pattern cannot carry
    // both guards — repeating the body is the only way to write this.
    await assertNoDiagnostics(r'''
String f(int x) => switch (x) {
  int() when x > 10 => 'big',
  int() when x < -10 => 'big',
  _ => 'small',
};
''');
  }

  Future<void> test_guardedCaseInSwitchStatement() async {
    await assertNoDiagnostics(r'''
void f(Object x) {
  switch (x) {
    case int() when x == 1:
      print('a');
      break;
    case int() when x == 2:
      print('a');
      break;
  }
}
''');
  }

  Future<void> test_bodiesDifferingOnlyByVariable() async {
    await assertNoDiagnostics(r'''
String f(int x, String a, String b) => switch (x) {
  1 => a,
  2 => b,
  _ => 'c',
};
''');
  }
}
