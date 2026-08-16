import 'package:many_lints/src/rules/prefer_conditional_expressions.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferConditionalExpressionsTest),
  );
}

@reflectiveTest
class PreferConditionalExpressionsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferConditionalExpressions();
    super.setUp();
  }

  Future<void> test_bothBranchesAssign() async {
    await assertDiagnostics(
      r'''
void f(bool active) {
  String label;
  if (active) {
    label = 'On';
  } else {
    label = 'Off';
  }
  print(label);
}
''',
      [lint(40, 2)],
    );
  }

  Future<void> test_bothBranchesReturn() async {
    await assertDiagnostics(
      r'''
String f(bool active) {
  if (active) {
    return 'On';
  } else {
    return 'Off';
  }
}
''',
      [lint(26, 2)],
    );
  }

  Future<void> test_differentTargets() async {
    await assertNoDiagnostics(r'''
void f(bool active) {
  String a = '';
  String b = '';
  if (active) {
    a = 'On';
  } else {
    b = 'Off';
  }
  print('$a$b');
}
''');
  }

  Future<void> test_severalStatementsInABranch() async {
    await assertNoDiagnostics(r'''
void f(bool active) {
  String label;
  if (active) {
    print('x');
    label = 'On';
  } else {
    label = 'Off';
  }
  print(label);
}
''');
  }

  Future<void> test_noElseBranch() async {
    await assertNoDiagnostics(r'''
void f(bool active) {
  String label = '';
  if (active) {
    label = 'On';
  }
  print(label);
}
''');
  }

  // Different operators are not a choice between two values.
  Future<void> test_differentAssignmentOperators() async {
    await assertNoDiagnostics(r'''
void f(bool active) {
  int n = 0;
  if (active) {
    n = 1;
  } else {
    n += 2;
  }
  print(n);
}
''');
  }

  Future<void> test_elseIfChain() async {
    await assertNoDiagnostics(r'''
String f(int n) {
  if (n == 1) {
    return 'one';
  } else if (n == 2) {
    return 'two';
  }
  return 'many';
}
''');
  }
}
