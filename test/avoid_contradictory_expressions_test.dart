import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_contradictory_expressions.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidContradictoryExpressionsTest),
  );
}

@reflectiveTest
class AvoidContradictoryExpressionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidContradictoryExpressions();
    super.setUp();
  }

  // ── Positive cases (should trigger lint) ──────────────────────────

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

  // ── Negative cases (should NOT trigger lint) ──────────────────────

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
    // Redundant but not contradictory.
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
    // x == a && x == b where a, b are variables — not provably different.
    await assertNoDiagnostics(r'''
void f(int x, int a, int b) {
  x == a && x == b;
}
''');
  }

  // ── Operand swapping (line 104: _flipOperator path) ────────────────

  Future<void> test_swappedOperands_equalAndNotEqual() async {
    // a == x && x != a — operands are swapped between the two comparisons.
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
    // a < x && x > a — after flipping b.op (GT→LT), both become LT on same
    // pair, which is NOT contradictory (same op). So no lint.
    await assertNoDiagnostics(r'''
void f(int x, int a) {
  a < x && x > a;
}
''');
  }

  // ── _hasDifferentLiteralValues orientation checks (lines 144,148,152) ──

  Future<void> test_equalEqual_rightSharedOperand_differentLiterals() async {
    // 3 == x && 4 == x — shared operand is on the right of both.
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
    // x == 3 && 4 == x — shared operand: a.left == b.right, different: a.right vs b.left.
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
    // 3 == x && x == 4 — shared operand: a.right == b.left, different: a.left vs b.right.
    await assertDiagnostics(
      r'''
void f(int x) {
  3 == x && x == 4;
}
''',
      [lint(18, 16)],
    );
  }

  // ── Parenthesized expressions (lines 163,166,205,208) ──────────────

  Future<void> test_parenthesized_literals() async {
    // x == (3) && x == (4) — parenthesized literals should be unwrapped.
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
    // (x) == 3 && (x) != 3 — parenthesized identifiers should be unwrapped.
    await assertDiagnostics(
      r'''
void f(int x) {
  (x) == 3 && (x) != 3;
}
''',
      [lint(18, 20)],
    );
  }

  // ── DoubleLiteral comparison (line 173) ────────────────────────────

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

  // ── BooleanLiteral in _sameExpression (line 189 area) ──────────────

  Future<void> test_equalEqual_sameBoolLiteral_noLint() async {
    // x == true && x == true — same literal, not contradictory.
    await assertNoDiagnostics(r'''
void f(bool x) {
  x == true && x == true;
}
''');
  }

  // ── PrefixExpression comparison (lines 248-249) ────────────────────

  Future<void> test_prefixExpression_sameNegativeLiteral_noLint() async {
    // x == -1 && x == -1 — same prefix expression, not contradictory.
    await assertNoDiagnostics(r'''
void f(int x) {
  x == -1 && x == -1;
}
''');
  }

  Future<void> test_prefixExpression_equalAndNotEqual() async {
    // x == -1 && x != -1 — same prefix expression, contradictory operators.
    await assertDiagnostics(
      r'''
void f(int x) {
  x == -1 && x != -1;
}
''',
      [lint(18, 18)],
    );
  }

  // ── PropertyAccess element matching (lines 223-226) ────────────────

  Future<void> test_propertyAccess_contradictory() async {
    // obj.value == 3 && obj.value == 4 — property access on same target.
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

  // ── PrefixedIdentifier element matching (lines 217-219) ────────────

  Future<void> test_prefixedIdentifier_equalAndNotEqual() async {
    // x == Color.red && x != Color.red — same prefixed identifier, contradictory.
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

  // ── DoubleLiteral in _sameExpression (line 234) ────────────────────

  Future<void> test_equalEqual_sameDoubleLiteralValues_noLint() async {
    // x == 1.0 && x == 1.0 — same double literal, not contradictory.
    await assertNoDiagnostics(r'''
void f(double x) {
  x == 1.0 && x == 1.0;
}
''');
  }

  // ── StringLiteral in _areDifferentLiterals (line 176 area) ─────────

  Future<void> test_equalEqual_sameStringLiteralValues_noLint() async {
    await assertNoDiagnostics(r'''
void f(String x) {
  x == 'hello' && x == 'hello';
}
''');
  }

  // ── _flipOperator for LT, LT_EQ and GT_EQ (lines 191,193-194) ─────

  Future<void> test_swappedOperands_equalAndLessThan_flipped() async {
    // a == x && x < a — flip LT→GT: a == x && a > x — contradictory (EQ_EQ, GT).
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
    // a <= x && x >= a — flip GT_EQ→LT_EQ: a <= x && a <= x — same op, NOT contradictory.
    await assertNoDiagnostics(r'''
void f(int x, int a) {
  a <= x && x >= a;
}
''');
  }

  Future<void> test_swappedOperands_greaterThanEqual_noLint() async {
    // a >= x && x <= a — flip LT_EQ→GT_EQ: a >= x && a >= x — same op, NOT contradictory.
    await assertNoDiagnostics(r'''
void f(int x, int a) {
  a >= x && x <= a;
}
''');
  }

  // --- Cover PropertyAccess _sameExpression (lines 224-226) ---

  Future<void> test_propertyAccess_contradictory_equalNotEqual() async {
    // obj.value == 3 && obj.value != 3 — exercises PropertyAccess path
    // in _sameExpression (lines 223-226)
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
    // a.value == 3 && b.value == 4 — the rule sees same field element,
    // so it reports a contradiction (same field identifier, different literals)
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

  // --- Cover PropertyAccess via parenthesized target (lines 224-226) ---

  Future<void> test_propertyAccess_parenthesized_contradictory() async {
    // (obj).value forces PropertyAccess (not PrefixedIdentifier)
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
    // (obj).value == 3 && (obj).value == 3 — not contradictory (same value)
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
