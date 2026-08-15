import 'package:many_lints/src/rules/no_equal_conditions.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(NoEqualConditionsTest));
}

@reflectiveTest
class NoEqualConditionsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = NoEqualConditions();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_repeatedConditionInChain() async {
    await assertDiagnostics(
      r'''
String f(int x) {
  if (x > 0) {
    return 'a';
  } else if (x > 0) {
    return 'b';
  }
  return 'c';
}
''',
      [lint(62, 5)],
    );
  }

  Future<void> test_repeatedAfterAnUnrelatedBranch() async {
    await assertDiagnostics(
      r'''
String f(int x) {
  if (x > 0) {
    return 'a';
  } else if (x < 0) {
    return 'b';
  } else if (x > 0) {
    return 'c';
  }
  return 'd';
}
''',
      [lint(100, 5)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_distinctConditions() async {
    await assertNoDiagnostics(r'''
String f(int x) {
  if (x > 0) {
    return 'a';
  } else if (x < 0) {
    return 'b';
  }
  return 'c';
}
''');
  }

  Future<void> test_separateChains() async {
    // Two independent `if`s test the same thing at different points, which is
    // normal — the first may have changed the state the second reads.
    await assertNoDiagnostics(r'''
void f(int x) {
  if (x > 0) {
    print('a');
  }
  if (x > 0) {
    print('b');
  }
}
''');
  }

  Future<void> test_nestedIfIsItsOwnChain() async {
    await assertNoDiagnostics(r'''
void f(int x, int y) {
  if (x > 0) {
    if (y > 0) {
      print('a');
    }
  }
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_patternCaseBindsVariables() async {
    // Two `case` clauses that read alike need not test the same thing.
    await assertNoDiagnostics(r'''
String f(Object x) {
  if (x case int()) {
    return 'a';
  } else if (x case int()) {
    return 'b';
  }
  return 'c';
}
''');
  }
}
