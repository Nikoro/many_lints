import 'package:many_lints/src/rules/avoid_negated_conditions.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidNegatedConditionsTest),
  );
}

@reflectiveTest
class AvoidNegatedConditionsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidNegatedConditions();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_negatedIfElse() async {
    await assertDiagnostics(
      r'''
void f(bool ok) {
  if (!ok) {
    print(1);
  } else {
    print(2);
  }
}
''',
      [lint(24, 3)],
    );
  }

  Future<void> test_notEqualIfElse() async {
    await assertDiagnostics(
      r'''
void f(int a, int b) {
  if (a != b) {
    print(1);
  } else {
    print(2);
  }
}
''',
      [lint(29, 6)],
    );
  }

  // These two are the false positives a production run produced: `!= null` and
  // `!= 0` read as positive assertions, so inverting them makes code worse.
  Future<void> test_notEqualNullIsAPositiveAssertion() async {
    await assertNoDiagnostics(r'''
void f(int? a) {
  if (a != null) {
    print(1);
  } else {
    print(2);
  }
}
''');
  }

  Future<void> test_notEqualZeroIsTheComparatorIdiom() async {
    await assertNoDiagnostics(r'''
int f(int byPoints, int fallback) => byPoints != 0 ? byPoints : fallback;
''');
  }

  Future<void> test_negatedConditionalExpression() async {
    await assertDiagnostics(
      r'''
int f(bool ok) => !ok ? 1 : 2;
''',
      [lint(18, 3)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_guardWithoutElse() async {
    await assertNoDiagnostics(r'''
void f(bool ok) {
  if (!ok) {
    print(1);
  }
}
''');
  }

  Future<void> test_positiveIfElse() async {
    await assertNoDiagnostics(r'''
void f(bool ok) {
  if (ok) {
    print(1);
  } else {
    print(2);
  }
}
''');
  }

  Future<void> test_elseIfChainIsOrdered() async {
    await assertNoDiagnostics(r'''
void f(int n) {
  if (n != 1) {
    print(1);
  } else if (n == 2) {
    print(2);
  }
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_patternIfBindsVariables() async {
    await assertNoDiagnostics(r'''
void f(Object o) {
  if (o case final int n) {
    print(n);
  } else {
    print(0);
  }
}
''');
  }

  Future<void> test_parenthesizedNegation() async {
    await assertDiagnostics(
      r'''
void f(bool ok) {
  if ((!ok)) {
    print(1);
  } else {
    print(2);
  }
}
''',
      [lint(24, 5)],
    );
  }
}
