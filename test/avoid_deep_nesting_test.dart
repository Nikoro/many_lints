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

  Future<void> test_elseIfChainIsNotNesting() async {
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
