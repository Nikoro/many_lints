import 'package:many_lints/src/rules/avoid_complex_conditions.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidComplexConditionsTest),
  );
}

@reflectiveTest
class AvoidComplexConditionsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidComplexConditions();
    super.setUp();
  }

  Future<void> test_fourOperands() async {
    await assertDiagnostics(
      r'''
bool f(bool a, bool b, bool c, bool d) => a && b && c && d;
''',
      [lint(42, 16)],
    );
  }

  Future<void> test_mixedOperators() async {
    await assertDiagnostics(
      r'''
bool f(bool a, bool b, bool c, bool d) => a && b || c && d;
''',
      [lint(42, 16)],
    );
  }

  Future<void> test_threeOperandsIsWithinBudget() async {
    await assertNoDiagnostics(r'''
bool f(bool a, bool b, bool c) => a && b && c;
''');
  }

  Future<void> test_singleComparison() async {
    await assertNoDiagnostics(r'''
bool f(int x) => x > 0;
''');
  }

  Future<void> test_arithmeticIsNotACondition() async {
    await assertNoDiagnostics(r'''
int f(int a, int b, int c, int d) => a + b + c + d;
''');
  }

  Future<void> test_reportedOnceAtTheRoot() async {
    await assertDiagnostics(
      r'''
bool f(bool a, bool b, bool c, bool d, bool e) =>
    a && b && c && d && e;
''',
      [lint(54, 21)],
    );
  }

  Future<void> test_equalityOperatorIsOneChainByConstruction() async {
    await assertNoDiagnostics(r'''
class Point {
  const Point(this.x, this.y, this.z, this.w);

  final int x;
  final int y;
  final int z;
  final int w;

  @override
  bool operator ==(Object other) =>
      other is Point &&
      other.x == x &&
      other.y == y &&
      other.z == z &&
      other.w == w;

  @override
  int get hashCode => 0;
}
''');
  }

  Future<void> test_parenthesesDoNotBreakTheChain() async {
    await assertDiagnostics(
      r'''
bool f(bool a, bool b, bool c, bool d) => (a && b) && (c && d);
''',
      [lint(42, 20)],
    );
  }
}
