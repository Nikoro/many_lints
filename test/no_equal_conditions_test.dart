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

  Future<void> test_separateIfChainsMayRetestChangedState() async {
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

  Future<void> test_lookalikePatternCasesBindingVariables_noLint() async {
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
