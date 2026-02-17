import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_constant_switches.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidConstantSwitchesTest));
}

@reflectiveTest
class AvoidConstantSwitchesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidConstantSwitches();
    super.setUp();
  }

  // ── Positive cases (should trigger lint) ──────────────────────────

  Future<void> test_switchStatementOnIntLiteral() async {
    await assertDiagnostics(
      r'''
void f() {
  switch (42) {
    case 42:
      break;
  }
}
''',
      [lint(21, 2)],
    );
  }

  Future<void> test_switchStatementOnStringLiteral() async {
    await assertDiagnostics(
      r'''
void f() {
  switch ('hello') {
    case 'hello':
      break;
  }
}
''',
      [lint(21, 7)],
    );
  }

  Future<void> test_switchStatementOnConstVariable() async {
    await assertDiagnostics(
      r'''
const x = 10;
void f() {
  switch (x) {
    case 10:
      break;
  }
}
''',
      [lint(35, 1)],
    );
  }

  Future<void> test_switchStatementOnStaticConstField() async {
    await assertDiagnostics(
      r'''
abstract final class Config {
  static const value = '1';
}
void f() {
  switch (Config.value) {
    case '1':
      break;
    default:
      break;
  }
}
''',
      [lint(81, 12)],
    );
  }

  Future<void> test_switchExpressionOnIntLiteral() async {
    await assertDiagnostics(
      r'''
void f() {
  final x = switch (42) {
    42 => 'yes',
    _ => 'no',
  };
}
''',
      [lint(31, 2)],
    );
  }

  Future<void> test_switchExpressionOnConstVariable() async {
    await assertDiagnostics(
      r'''
const val = 'a';
void f() {
  final x = switch (val) {
    'a' => 1,
    _ => 2,
  };
}
''',
      [lint(48, 3)],
    );
  }

  Future<void> test_switchStatementOnBoolLiteral() async {
    await assertDiagnostics(
      r'''
void f() {
  switch (true) {
    case true:
      break;
    default:
      break;
  }
}
''',
      [lint(21, 4)],
    );
  }

  Future<void> test_switchStatementOnNegativeNumber() async {
    await assertDiagnostics(
      r'''
void f() {
  switch (-1) {
    case -1:
      break;
    default:
      break;
  }
}
''',
      [lint(21, 2)],
    );
  }

  // ── Negative cases (should NOT trigger lint) ──────────────────────

  Future<void> test_switchStatementOnParameter_noLint() async {
    await assertNoDiagnostics(r'''
void f(int x) {
  switch (x) {
    case 1:
      break;
  }
}
''');
  }

  Future<void> test_switchExpressionOnParameter_noLint() async {
    await assertNoDiagnostics(r'''
String f(int x) {
  return switch (x) {
    1 => 'one',
    _ => 'other',
  };
}
''');
  }

  Future<void> test_switchStatementOnMethodCall_noLint() async {
    await assertNoDiagnostics(r'''
int getValue() => 1;
void f() {
  switch (getValue()) {
    case 1:
      break;
  }
}
''');
  }

  Future<void> test_switchStatementOnNonConstFinal_noLint() async {
    await assertNoDiagnostics(r'''
void f(int x) {
  final y = x + 1;
  switch (y) {
    case 1:
      break;
  }
}
''');
  }

  Future<void> test_switchStatementOnPropertyAccess_noLint() async {
    await assertNoDiagnostics(r'''
void f(List<int> list) {
  switch (list.length) {
    case 0:
      break;
  }
}
''');
  }
}
