import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/avoid_equal_expressions.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidEqualExpressionsTest));
}

@reflectiveTest
class AvoidEqualExpressionsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidEqualExpressions();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_identicalEquality() async {
    await assertDiagnostics(
      r'''
bool check(int a) {
  return a == a;
}
''',
      [lint(29, 6)],
    );
  }

  Future<void> test_identicalLogicalAnd() async {
    await assertDiagnostics(
      r'''
bool check(bool flag) {
  return flag && flag;
}
''',
      [lint(33, 12)],
    );
  }

  Future<void> test_identicalComparison() async {
    await assertDiagnostics(
      r'''
bool check(int a) {
  return a < a;
}
''',
      [lint(29, 5)],
    );
  }

  Future<void> test_identicalSubtraction() async {
    await assertDiagnostics(
      r'''
int check(int a) {
  return a - a;
}
''',
      [lint(28, 5)],
    );
  }

  Future<void> test_identicalPropertyAccess() async {
    await assertDiagnostics(
      r'''
class Point {
  const Point(this.x, this.y);
  final int x;
  final int y;
}

bool check(Point p) {
  return p.x == p.x;
}
''',
      [lint(109, 10)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_differentOperands() async {
    await assertNoDiagnostics(r'''
class Point {
  const Point(this.x, this.y);
  final int x;
  final int y;
}

bool check(Point p) {
  return p.x == p.y;
}
''');
  }

  Future<void> test_nanCheckOnDouble() async {
    await assertNoDiagnostics(r'''
bool isNaN(double value) {
  return value != value;
}
''');
  }

  Future<void> test_nanCheckOnNum() async {
    await assertNoDiagnostics(r'''
bool isNaN(num value) {
  return value != value;
}
''');
  }

  Future<void> test_methodCallOperands() async {
    await assertNoDiagnostics(r'''
class Generator {
  int next() => 0;
}

bool check(Generator g) {
  return g.next() == g.next();
}
''');
  }

  Future<void> test_addition() async {
    await assertNoDiagnostics(r'''
int double_(int a) {
  return a + a;
}
''');
  }

  Future<void> test_multiplication() async {
    await assertNoDiagnostics(r'''
int square(int a) {
  return a * a;
}
''');
  }

  Future<void> test_differentIndices() async {
    await assertNoDiagnostics(r'''
bool check(List<int> items) {
  return items[0] == items[1];
}
''');
  }
}
