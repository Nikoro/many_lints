import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_switch_expression.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferSwitchExpressionTest),
  );
}

@reflectiveTest
class PreferSwitchExpressionTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferSwitchExpression();
    super.setUp();
  }

  Future<void> test_returnBased_simple() async {
    await assertDiagnostics(
      r'''
String getType(int value) {
  switch (value) {
    case 1:
      return 'first';
    case 2:
      return 'second';
  }
  return 'default';
}
''',
      [lint(30, 6)],
    );
  }

  Future<void> test_returnBased_withDefault() async {
    await assertDiagnostics(
      r'''
String getType(int value) {
  switch (value) {
    case 1:
      return 'first';
    case 2:
      return 'second';
    default:
      return 'default';
  }
}
''',
      [lint(30, 6)],
    );
  }

  Future<void> test_returnBased_enum() async {
    await assertDiagnostics(
      r'''
enum Color { red, blue, green }

String getName(Color color) {
  switch (color) {
    case Color.red:
      return 'Red';
    case Color.blue:
      return 'Blue';
    case Color.green:
      return 'Green';
  }
}
''',
      [lint(65, 6)],
    );
  }

  Future<void> test_assignmentBased_simple() async {
    await assertDiagnostics(
      r'''
String getType(int value) {
  String result = '';
  switch (value) {
    case 1:
      result = 'first';
    case 2:
      result = 'second';
  }
  return result;
}
''',
      [lint(52, 6)],
    );
  }

  Future<void> test_assignmentBased_withDefault() async {
    await assertDiagnostics(
      r'''
String getType(int value) {
  String result = '';
  switch (value) {
    case 1:
      result = 'first';
    case 2:
      result = 'second';
    default:
      result = 'default';
  }
  return result;
}
''',
      [lint(52, 6)],
    );
  }

  Future<void> test_noTrigger_fallthroughCase() async {
    await assertNoDiagnostics(r'''
String getType(int value) {
  switch (value) {
    case 1:
    case 2:
      return 'first or second';
    case 3:
      return 'third';
  }
  return 'default';
}
''');
  }

  Future<void> test_noTrigger_multipleStatements() async {
    await assertNoDiagnostics(r'''
String getType(int value) {
  switch (value) {
    case 1:
      print('one');
      return 'first';
    case 2:
      return 'second';
  }
  return 'default';
}
''');
  }

  Future<void> test_noTrigger_noReturnExpression() async {
    await assertNoDiagnostics(r'''
void doSomething(int value) {
  switch (value) {
    case 1:
      return;
    case 2:
      return;
  }
}
''');
  }

  Future<void> test_noTrigger_mixedAssignments() async {
    await assertNoDiagnostics(r'''
String getType(int value) {
  String result = '';
  String other = '';
  switch (value) {
    case 1:
      result = 'first';
    case 2:
      other = 'second';
  }
  return result;
}
''');
  }

  Future<void> test_noTrigger_mixedReturnAndAssignment() async {
    await assertNoDiagnostics(r'''
String getType(int value) {
  String result = '';
  switch (value) {
    case 1:
      return 'first';
    case 2:
      result = 'second';
  }
  return result;
}
''');
  }

  Future<void> test_noTrigger_emptySwitch() async {
    await assertNoDiagnostics(r'''
String getType(int value) {
  switch (value) {
  }
  return 'default';
}
''');
  }

  Future<void> test_returnBased_complexExpression() async {
    await assertDiagnostics(
      r'''
int calculate(int value) {
  switch (value) {
    case 1:
      return value * 2;
    case 2:
      return value + 10;
    case 3:
      return value - 5;
  }
  return 0;
}
''',
      [lint(29, 6)],
    );
  }

  Future<void> test_assignmentBased_complexExpression() async {
    await assertDiagnostics(
      r'''
int calculate(int value) {
  int result = 0;
  switch (value) {
    case 1:
      result = value * 2;
    case 2:
      result = value + 10;
    case 3:
      result = value - 5;
  }
  return result;
}
''',
      [lint(47, 6)],
    );
  }

  Future<void> test_returnBased_stringLiterals() async {
    await assertDiagnostics(
      r'''
String getMessage(bool flag) {
  switch (flag) {
    case true:
      return 'yes';
    case false:
      return 'no';
  }
}
''',
      [lint(33, 6)],
    );
  }

  Future<void> test_noTrigger_breakStatement() async {
    await assertNoDiagnostics(r'''
String getType(int value) {
  String result = 'default';
  switch (value) {
    case 1:
      result = 'first';
      break;
    case 2:
      result = 'second';
      break;
  }
  return result;
}
''');
  }
}
