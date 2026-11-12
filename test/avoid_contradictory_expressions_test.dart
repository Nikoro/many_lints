import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/avoid_contradictory_expressions.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidContradictoryExpressionsTest),
  );
}

@reflectiveTest
class AvoidContradictoryExpressionsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidContradictoryExpressions();
    super.setUp();
  }

  Future<void> test_equalEqual_differentIntLiterals() async {
    await assertDiagnostics(
      r'''
void f(int x) {
  x == 3 && x == 4;
}
''',
      [lint(18, 16)],
    );
  }

  Future<void> test_equalEqual_differentStringLiterals() async {
    await assertDiagnostics(
      r'''
void f(String x) {
  x == 'a' && x == 'b';
}
''',
      [lint(21, 20)],
    );
  }

  Future<void> test_equalAndNotEqual_sameOperands() async {
    await assertDiagnostics(
      r'''
void f(int x) {
  x == 2 && x != 2;
}
''',
      [lint(18, 16)],
    );
  }

  Future<void> test_lessThanAndGreaterThan_sameOperands() async {
    await assertDiagnostics(
      r'''
void f(int x) {
  x < 4 && x > 4;
}
''',
      [lint(18, 14)],
    );
  }

  Future<void> test_equalAndLessThan_sameOperands() async {
    await assertDiagnostics(
      r'''
void f(int x) {
  x == 4 && x < 4;
}
''',
      [lint(18, 15)],
    );
  }

  Future<void> test_equalAndGreaterThan_sameOperands() async {
    await assertDiagnostics(
      r'''
void f(int x) {
  x == 4 && x > 4;
}
''',
      [lint(18, 15)],
    );
  }

  Future<void> test_variableComparedToVariable_contradictory() async {
    await assertDiagnostics(
      r'''
void f(int x, int y) {
  x == y && x != y;
}
''',
      [lint(25, 16)],
    );
  }

  Future<void> test_chainedAnd_contradictionInChain() async {
    await assertDiagnostics(
      r'''
void f(int a, bool b) {
  a == 1 && b && a == 3;
}
''',
      [lint(26, 21)],
    );
  }

  Future<void> test_equalEqual_differentBoolLiterals() async {
    await assertDiagnostics(
      r'''
void f(bool x) {
  x == true && x == false;
}
''',
      [lint(19, 23)],
    );
  }

  Future<void> test_orOperator_noLint() async {
    await assertNoDiagnostics(r'''
void f(int x) {
  x == 3 || x == 4;
}
''');
  }

  Future<void> test_consistentRange_noLint() async {
    await assertNoDiagnostics(r'''
void f(int x) {
  x < 4 && x > 2;
}
''');
  }

  Future<void> test_singleComparison_noLint() async {
    await assertNoDiagnostics(r'''
void f(int x) {
  x == 2;
}
''');
  }

  Future<void> test_sameEqualityTwice_noLint() async {
    await assertNoDiagnostics(r'''
void f(int x) {
  x == 3 && x == 3;
}
''');
  }

  Future<void> test_differentVariables_noLint() async {
    await assertNoDiagnostics(r'''
void f(int x, int y) {
  x == 3 && y == 4;
}
''');
  }

  Future<void> test_nonComparisonOperator_noLint() async {
    await assertNoDiagnostics(r'''
void f(int x) {
  x + 3 > 0 && x - 1 < 10;
}
''');
  }

  Future<void> test_equalEqual_differentVariableValues_noLint() async {
    await assertNoDiagnostics(r'''
void f(int x, int a, int b) {
  x == a && x == b;
}
''');
  }

  Future<void> test_swappedOperands_equalAndNotEqual() async {
    await assertDiagnostics(
      r'''
void f(int x, int a) {
  a == x && x != a;
}
''',
      [lint(25, 16)],
    );
  }

  Future<void> test_swappedOperands_lessThanAndLessThan() async {
    await assertNoDiagnostics(r'''
void f(int x, int a) {
  a < x && x > a;
}
''');
  }

  Future<void> test_equalEqual_rightSharedOperand_differentLiterals() async {
    await assertDiagnostics(
      r'''
void f(int x) {
  3 == x && 4 == x;
}
''',
      [lint(18, 16)],
    );
  }

  Future<void> test_equalEqual_crossShared_leftRight() async {
    await assertDiagnostics(
      r'''
void f(int x) {
  x == 3 && 4 == x;
}
''',
      [lint(18, 16)],
    );
  }

  Future<void> test_equalEqual_crossShared_rightLeft() async {
    await assertDiagnostics(
      r'''
void f(int x) {
  3 == x && x == 4;
}
''',
      [lint(18, 16)],
    );
  }

  Future<void> test_parenthesized_literals() async {
    await assertDiagnostics(
      r'''
void f(int x) {
  x == (3) && x == (4);
}
''',
      [lint(18, 20)],
    );
  }

  Future<void> test_parenthesized_identifiers() async {
    await assertDiagnostics(
      r'''
void f(int x) {
  (x) == 3 && (x) != 3;
}
''',
      [lint(18, 20)],
    );
  }

  Future<void> test_equalEqual_differentDoubleLiterals() async {
    await assertDiagnostics(
      r'''
void f(double x) {
  x == 1.0 && x == 2.0;
}
''',
      [lint(21, 20)],
    );
  }

  Future<void> test_equalEqual_sameBoolLiteral_noLint() async {
    await assertNoDiagnostics(r'''
void f(bool x) {
  x == true && x == true;
}
''');
  }

  Future<void> test_prefixExpression_sameNegativeLiteral_noLint() async {
    await assertNoDiagnostics(r'''
void f(int x) {
  x == -1 && x == -1;
}
''');
  }

  Future<void> test_prefixExpression_equalAndNotEqual() async {
    await assertDiagnostics(
      r'''
void f(int x) {
  x == -1 && x != -1;
}
''',
      [lint(18, 18)],
    );
  }

  Future<void> test_propertyAccess_contradictory() async {
    await assertDiagnostics(
      r'''
class A {
  int value = 0;
}

void f(A obj) {
  obj.value == 3 && obj.value == 4;
}
''',
      [lint(48, 32)],
    );
  }

  Future<void> test_prefixedIdentifier_equalAndNotEqual() async {
    await assertDiagnostics(
      r'''
enum Color { red, blue }

void f(Color x) {
  x == Color.red && x != Color.red;
}
''',
      [lint(46, 32)],
    );
  }

  Future<void> test_equalEqual_sameDoubleLiteralValues_noLint() async {
    await assertNoDiagnostics(r'''
void f(double x) {
  x == 1.0 && x == 1.0;
}
''');
  }

  Future<void> test_equalEqual_sameStringLiteralValues_noLint() async {
    await assertNoDiagnostics(r'''
void f(String x) {
  x == 'hello' && x == 'hello';
}
''');
  }

  Future<void> test_swappedOperands_equalAndLessThan_flipped() async {
    await assertDiagnostics(
      r'''
void f(int x, int a) {
  a == x && x < a;
}
''',
      [lint(25, 15)],
    );
  }

  Future<void> test_swappedOperands_lessThanEqual_noLint() async {
    await assertNoDiagnostics(r'''
void f(int x, int a) {
  a <= x && x >= a;
}
''');
  }

  Future<void> test_swappedOperands_greaterThanEqual_noLint() async {
    await assertNoDiagnostics(r'''
void f(int x, int a) {
  a >= x && x <= a;
}
''');
  }

  Future<void> test_propertyAccess_contradictory_equalNotEqual() async {
    await assertDiagnostics(
      r'''
class A {
  int value = 0;
}

void f(A obj) {
  obj.value == 3 && obj.value != 3;
}
''',
      [lint(48, 32)],
    );
  }

  Future<void> test_propertyAccess_differentTargets() async {
    await assertDiagnostics(
      r'''
class A {
  int value = 0;
}

void f(A a, A b) {
  a.value == 3 && b.value == 4;
}
''',
      [lint(51, 28)],
    );
  }

  Future<void> test_propertyAccess_parenthesized_contradictory() async {
    await assertDiagnostics(
      r'''
class A {
  int value = 0;
}

void f(A obj) {
  (obj).value == 3 && (obj).value == 4;
}
''',
      [lint(48, 36)],
    );
  }

  Future<void> test_propertyAccess_parenthesized_sameValue_noLint() async {
    await assertNoDiagnostics(r'''
class A {
  int value = 0;
}

void f(A obj) {
  (obj).value == 3 && (obj).value == 3;
}
''');
  }
}
