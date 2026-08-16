import 'package:many_lints/src/rules/avoid_deep_nesting.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidDeepNestingTest));
}

@reflectiveTest
class AvoidDeepNestingTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidDeepNesting();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_fiveLevelsOfNesting() async {
    await assertDiagnostics(
      r'''
void f(List<List<int>> rows, bool flag) {
  if (flag) {
    for (final row in rows) {
      for (final cell in row) {
        if (cell > 0) {
          while (cell > 1) {
            print(cell);
          }
        }
      }
    }
  }
}
''',
      [lint(152, 5)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_fourLevelsIsWithinBudget() async {
    await assertNoDiagnostics(r'''
void f(List<List<int>> rows, bool flag) {
  if (flag) {
    for (final row in rows) {
      for (final cell in row) {
        if (cell > 0) print(cell);
      }
    }
  }
}
''');
  }

  Future<void> test_flatCode() async {
    await assertNoDiagnostics(r'''
void f(int n) {
  if (n < 0) return;
  print(n);
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_elseIfChainIsNotNesting() async {
    // An else-if chain is written flat and reads flat, so a long dispatch
    // must not be reported as deep nesting.
    await assertNoDiagnostics(r'''
String f(int n) {
  if (n == 1) {
    return 'one';
  } else if (n == 2) {
    return 'two';
  } else if (n == 3) {
    return 'three';
  } else if (n == 4) {
    return 'four';
  } else if (n == 5) {
    return 'five';
  }
  return 'many';
}
''');
  }

  Future<void> test_nestedFunctionStartsItsOwnCount() async {
    // Two levels here plus three inside the callback is not five: the
    // callback's body is not reached through the enclosing nest.
    await assertNoDiagnostics(r'''
void f(List<int> xs, bool flag) {
  if (flag) {
    for (final x in xs) {
      xs.forEach((e) {
        if (e > 0) {
          for (var i = 0; i < e; i++) {
            print(i);
          }
        }
      });
    }
  }
}
''');
  }

  Future<void> test_reportsOnceForOneFunction() async {
    // Two separate six-level nests in one function still report once, at the
    // first statement past the budget.
    await assertDiagnostics(
      r'''
void f(bool a, bool b, bool c, bool d, bool e) {
  if (a) {
    if (b) {
      if (c) {
        if (d) {
          if (e) print(1);
        }
      }
    }
  }
}
''',
      [lint(115, 2)],
    );
  }
}
