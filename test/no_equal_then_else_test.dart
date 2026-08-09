import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/no_equal_then_else.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(NoEqualThenElseTest));
}

@reflectiveTest
class NoEqualThenElseTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoEqualThenElse();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_identicalBlocks() async {
    await assertDiagnostics(
      r'''
void f(bool flag) {
  if (flag) {
    print('same');
  } else {
    print('same');
  }
}
''',
      [lint(22, 64)],
    );
  }

  Future<void> test_blockAndBareStatementMatch() async {
    await assertDiagnostics(
      r'''
void f(bool flag) {
  if (flag) {
    print('same');
  } else print('same');
}
''',
      [lint(22, 54)],
    );
  }

  Future<void> test_identicalConditionalExpression() async {
    await assertDiagnostics(
      r'''
int f(bool flag) => flag ? 1 : 1;
''',
      [lint(20, 12)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_differentBranches() async {
    await assertNoDiagnostics(r'''
void f(bool flag) {
  if (flag) {
    print('yes');
  } else {
    print('no');
  }
}
''');
  }

  Future<void> test_noElseBranch() async {
    await assertNoDiagnostics(r'''
void f(bool flag) {
  if (flag) {
    print('yes');
  }
}
''');
  }

  Future<void> test_differentConditionalExpression() async {
    await assertNoDiagnostics(r'''
int f(bool flag) => flag ? 1 : 2;
''');
  }

  // ---- Edge cases ----

  Future<void> test_elseIfChainIsIgnored() async {
    await assertNoDiagnostics(r'''
void f(int value) {
  if (value == 1) {
    print('one');
  } else if (value == 2) {
    print('one');
  }
}
''');
  }

  Future<void> test_emptyBranchesAreIgnored() async {
    await assertNoDiagnostics(r'''
void f(bool flag) {
  if (flag) {
  } else {
  }
}
''');
  }
}
