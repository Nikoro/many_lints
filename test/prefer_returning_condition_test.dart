import 'package:many_lints/src/rules/prefer_returning_condition.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferReturningConditionTest),
  );
}

@reflectiveTest
class PreferReturningConditionTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferReturningCondition();
    super.setUp();
  }

  Future<void> test_ifReturnTrueThenReturnFalse() async {
    await assertDiagnostics(
      r'''
bool f(int x) {
  if (x > 0) return true;
  return false;
}
''',
      [lint(18, 23)],
    );
  }

  Future<void> test_ifElseWithBlocks() async {
    await assertDiagnostics(
      r'''
bool f(int x) {
  if (x > 0) {
    return true;
  } else {
    return false;
  }
}
''',
      [lint(18, 62)],
    );
  }

  Future<void> test_returnsTheConditionAlready() async {
    await assertNoDiagnostics(r'''
bool f(int x) {
  return x > 0;
}
''');
  }

  Future<void> test_branchesReturnNonLiterals() async {
    await assertNoDiagnostics(r'''
bool f(int x, bool other) {
  if (x > 0) return other;
  return false;
}
''');
  }

  Future<void>
  test_bothBranchesSameLiteralIsLeftToAlwaysReturnsSameValue() async {
    await assertNoDiagnostics(r'''
bool f(int x) {
  if (x > 0) return true;
  return true;
}
''');
  }

  Future<void> test_branchDoesMoreThanReturn() async {
    await assertNoDiagnostics(r'''
bool f(int x) {
  if (x > 0) {
    print('positive');
    return true;
  }
  return false;
}
''');
  }

  Future<void> test_patternCaseBindsVariables() async {
    await assertNoDiagnostics(r'''
bool f(Object x) {
  if (x case int()) return true;
  return false;
}
''');
  }
}
