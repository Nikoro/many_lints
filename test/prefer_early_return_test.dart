import 'package:many_lints/src/rules/prefer_early_return.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferEarlyReturnTest));
}

@reflectiveTest
class PreferEarlyReturnTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferEarlyReturn();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_functionBodyWrappedInIf() async {
    await assertDiagnostics(
      r'''
void f(bool ok) {
  if (ok) {
    print(1);
    print(2);
    print(3);
  }
}
''',
      [lint(20, 2)],
    );
  }

  Future<void> test_methodBodyWrappedInIf() async {
    await assertDiagnostics(
      r'''
class C {
  void m(bool ok) {
    if (ok) {
      print(1);
      print(2);
      print(3);
    }
  }
}
''',
      [lint(34, 2)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_shortBodyIsNotWorthAGuard() async {
    await assertNoDiagnostics(r'''
void f(bool ok) {
  if (ok) {
    print(1);
  }
}
''');
  }

  Future<void> test_ifWithElseWouldSwapBranches() async {
    await assertNoDiagnostics(r'''
void f(bool ok) {
  if (ok) {
    print(1);
    print(2);
    print(3);
  } else {
    print(4);
  }
}
''');
  }

  Future<void> test_statementBeforeTheIfIsSetup() async {
    await assertNoDiagnostics(r'''
void f(bool ok) {
  print(0);
  if (ok) {
    print(1);
    print(2);
    print(3);
  }
}
''');
  }

  Future<void> test_alreadyAGuard() async {
    await assertNoDiagnostics(r'''
void f(bool ok) {
  if (!ok) return;
  print(1);
  print(2);
  print(3);
}
''');
  }

  // An already-negated condition inverts into a longer positive guard, so the
  // rewrite would read worse than the code it replaced. This is the exclusion
  // the rule's only production hit produced.
  Future<void> test_alreadyNegatedConditionIsLeftAlone() async {
    await assertNoDiagnostics(r'''
void f(Map<String, int> m, String k) {
  if (!m.containsKey(k)) {
    print(1);
    print(2);
    print(3);
  }
}
''');
  }

  Future<void> test_notEqualConditionIsLeftAlone() async {
    await assertNoDiagnostics(r'''
void f(int a, int b) {
  if (a != b) {
    print(1);
    print(2);
    print(3);
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
    print(n);
    print(n);
  }
}
''');
  }

  Future<void> test_emptyBody() async {
    await assertNoDiagnostics(r'''
void f(bool ok) {
}
''');
  }
}
