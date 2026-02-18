import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/use_existing_variable.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(UseExistingVariableTest));
}

@reflectiveTest
class UseExistingVariableTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = UseExistingVariable();
    super.setUp();
  }

  Future<void> test_duplicatePropertyAccess_triggers() async {
    await assertDiagnostics(
      r'''
void fn(String value) {
  final some = value.length.isOdd;
  print(value.length.isOdd);
}
''',
      [lint(67, 18)],
    );
  }

  Future<void> test_duplicateMethodCall_triggers() async {
    await assertDiagnostics(
      r'''
void fn(List<int> list) {
  final copy = list.toList();
  print(list.toList());
}
''',
      [lint(64, 13)],
    );
  }

  Future<void> test_multipleDuplicates_triggers() async {
    await assertDiagnostics(
      r'''
void fn(String value) {
  final len = value.length;
  print(value.length);
  print(value.length);
}
''',
      [lint(60, 12), lint(83, 12)],
    );
  }

  Future<void> test_noVariable_noLint() async {
    await assertNoDiagnostics(r'''
void fn(String value) {
  print(value.length.isOdd);
  print(value.length.isOdd);
}
''');
  }

  Future<void> test_differentExpression_noLint() async {
    await assertNoDiagnostics(r'''
void fn(String value) {
  final some = value.length.isOdd;
  print(value.length.isEven);
}
''');
  }

  Future<void> test_nonFinalVariable_noLint() async {
    await assertNoDiagnostics(r'''
void fn(String value) {
  var some = value.length.isOdd;
  print(value.length.isOdd);
  some = false;
}
''');
  }

  Future<void> test_expressionBeforeDeclaration_noLint() async {
    await assertNoDiagnostics(r'''
void fn(String value) {
  print(value.length.isOdd);
  final some = value.length.isOdd;
  print(some);
}
''');
  }

  Future<void> test_trivialLiteral_noLint() async {
    await assertNoDiagnostics(r'''
void fn() {
  final x = 42;
  print(42);
}
''');
  }

  Future<void> test_trivialIdentifier_noLint() async {
    await assertNoDiagnostics(r'''
void fn(int x) {
  final y = x;
  print(x);
}
''');
  }

  Future<void> test_nestedFunction_noLint() async {
    await assertNoDiagnostics(r'''
void fn(String value) {
  final some = value.length.isOdd;
  void inner() {
    print(value.length.isOdd);
  }
  inner();
}
''');
  }

  Future<void> test_constListLiteral_triggers() async {
    await assertDiagnostics(
      r'''
void fn() {
  const items = [1, 2, 3];
  print([1, 2, 3]);
}
''',
      [lint(47, 9)],
    );
  }

  Future<void> test_duplicateInCondition_triggers() async {
    await assertDiagnostics(
      r'''
void fn(String value) {
  final len = value.length;
  if (value.length > 5) {
    print('long');
  }
}
''',
      [lint(58, 12)],
    );
  }

  Future<void> test_duplicateInReturnStatement_triggers() async {
    await assertDiagnostics(
      r'''
bool fn(String value) {
  final odd = value.length.isOdd;
  return value.length.isOdd;
}
''',
      [lint(67, 18)],
    );
  }

  Future<void> test_sameInitializerDifferentBlocks_noLint() async {
    await assertNoDiagnostics(r'''
void fn(String value) {
  final some = value.length.isOdd;
  print(some);
}

void fn2(String value) {
  print(value.length.isOdd);
}
''');
  }

  Future<void> test_duplicateInstanceCreation_triggers() async {
    await assertDiagnostics(
      r'''
void fn() {
  final list = List<int>.filled(10, 0);
  print(List<int>.filled(10, 0));
}
''',
      [lint(60, 23)],
    );
  }

  Future<void> test_trivialNegativeLiteral_noLint() async {
    await assertNoDiagnostics(r'''
void fn() {
  final x = -1;
  print(-1);
}
''');
  }

  Future<void> test_trivialStringLiteral_noLint() async {
    await assertNoDiagnostics(r'''
void fn() {
  final x = 'hello';
  print('hello');
}
''');
  }

  Future<void> test_trivialBoolLiteral_noLint() async {
    await assertNoDiagnostics(r'''
void fn() {
  final x = true;
  print(true);
}
''');
  }

  Future<void> test_secondVariableInitializerFlagged() async {
    await assertDiagnostics(
      r'''
void fn(String value) {
  final a = value.length.isOdd;
  final b = value.length.isOdd;
  print(b);
}
''',
      [lint(68, 18)],
    );
  }
}
