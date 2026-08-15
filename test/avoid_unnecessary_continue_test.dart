import 'package:many_lints/src/rules/avoid_unnecessary_continue.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidUnnecessaryContinueTest),
  );
}

@reflectiveTest
class AvoidUnnecessaryContinueTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryContinue();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_trailingContinueInForEach() async {
    await assertDiagnostics(
      r'''
void f(List<int> xs) {
  for (final x in xs) {
    print(x);
    continue;
  }
}
''',
      [lint(65, 9)],
    );
  }

  Future<void> test_trailingContinueInWhile() async {
    await assertDiagnostics(
      r'''
void f() {
  var i = 0;
  while (i < 10) {
    i++;
    continue;
  }
}
''',
      [lint(56, 9)],
    );
  }

  Future<void> test_onlyStatementInBody() async {
    await assertDiagnostics(
      r'''
void f(List<int> xs) {
  for (final x in xs) {
    continue;
  }
}
''',
      [lint(51, 9)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_continueGuardingLaterStatements() async {
    await assertNoDiagnostics(r'''
void f(List<int> xs) {
  for (final x in xs) {
    if (x < 0) continue;
    print(x);
  }
}
''');
  }

  Future<void> test_labelledContinueTargetsOuterLoop() async {
    await assertNoDiagnostics(r'''
void f(List<List<int>> rows) {
  outer:
  for (final row in rows) {
    for (final x in row) {
      if (x < 0) continue outer;
      print(x);
    }
  }
}
''');
  }

  Future<void> test_continueAtEndOfThenBranch() async {
    // Skips the `else`, so it is doing real work.
    await assertNoDiagnostics(r'''
void f(List<int> xs) {
  for (final x in xs) {
    if (x < 0) {
      continue;
    } else {
      print(x);
    }
  }
}
''');
  }

  Future<void> test_breakIsNotContinue() async {
    await assertNoDiagnostics(r'''
void f(List<int> xs) {
  for (final x in xs) {
    print(x);
    break;
  }
}
''');
  }
}
