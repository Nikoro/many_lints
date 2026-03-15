import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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

  Future<void> test_duplicateIndexExpression_triggers() async {
    await assertDiagnostics(
      r'''
void fn(List<int> list) {
  final first = list[0];
  print(list[0]);
}
''',
      [lint(59, 7)],
    );
  }

  Future<void> test_duplicateBinaryExpression_triggers() async {
    await assertDiagnostics(
      r'''
void fn(int a, int b) {
  final sum = a + b;
  print(a + b);
}
''',
      [lint(53, 5)],
    );
  }

  Future<void> test_duplicateConditionalExpression_triggers() async {
    await assertDiagnostics(
      r'''
void fn(bool flag, int a, int b) {
  final val = flag ? a : b;
  print(flag ? a : b);
}
''',
      [lint(71, 12)],
    );
  }

  Future<void> test_duplicateFunctionExpressionInvocation_triggers() async {
    await assertDiagnostics(
      r'''
void fn(int Function(int) apply) {
  final result = apply(42);
  print(apply(42));
}
''',
      [lint(71, 9)],
    );
  }

  Future<void> test_duplicateCascadeExpression_triggers() async {
    await assertDiagnostics(
      r'''
void fn() {
  final list = []..add(1)..add(2);
  print([]..add(1)..add(2));
}
''',
      [lint(55, 18)],
    );
  }

  Future<void> test_duplicatePrefixExpression_triggers() async {
    await assertDiagnostics(
      r'''
void fn(List<int> list) {
  final notEmpty = !list.isEmpty;
  print(!list.isEmpty);
}
''',
      [lint(68, 13)],
    );
  }

  Future<void> test_duplicateAsExpression_triggers() async {
    await assertDiagnostics(
      r'''
void fn(dynamic d) {
  final s = d as String;
  print(d as String);
}
''',
      [error(diag.unnecessaryCast, 54, 11), lint(54, 11)],
    );
  }

  Future<void> test_duplicateIsExpression_triggers() async {
    await assertDiagnostics(
      r'''
void fn(Object obj) {
  final check = obj is String;
  print(obj is String);
}
''',
      [lint(61, 13)],
    );
  }

  Future<void> test_duplicateSetLiteral_triggers() async {
    await assertDiagnostics(
      r'''
void fn() {
  const items = {1, 2, 3};
  print({1, 2, 3});
}
''',
      [lint(47, 9)],
    );
  }

  Future<void> test_duplicateAwaitExpression_triggers() async {
    await assertDiagnostics(
      r'''
Future<int> getValue() async => 42;
void fn() async {
  final val = await getValue();
  print(await getValue());
}
''',
      [lint(94, 16)],
    );
  }

  Future<void> test_duplicateParenthesizedExpression_triggers() async {
    await assertDiagnostics(
      r'''
void fn(int a, int b) {
  final val = (a + b);
  print((a + b));
}
''',
      [lint(55, 7)],
    );
  }

  Future<void> test_trivialParenthesizedExpression_noLint() async {
    await assertNoDiagnostics(r'''
void fn() {
  final x = (42);
  print((42));
}
''');
  }

  // === Tests for super.visit*() branches (non-matching expressions) ===

  Future<void> test_nonMatchingInstanceCreation_noLint() async {
    // InstanceCreationExpression that doesn't match — super.visitInstanceCreationExpression is called
    await assertNoDiagnostics(r'''
void fn() {
  final list = List<int>.filled(10, 0);
  print(List<int>.filled(5, 1));
}
''');
  }

  Future<void> test_nonMatchingIndexExpression_noLint() async {
    // IndexExpression that doesn't match — super.visitIndexExpression is called
    await assertNoDiagnostics(r'''
void fn(List<int> list) {
  final first = list[0];
  print(list[1]);
}
''');
  }

  Future<void> test_nonMatchingBinaryExpression_noLint() async {
    // BinaryExpression that doesn't match — super.visitBinaryExpression is called
    await assertNoDiagnostics(r'''
void fn(int a, int b) {
  final sum = a + b;
  print(a - b);
}
''');
  }

  Future<void> test_nonMatchingConditionalExpression_noLint() async {
    // ConditionalExpression that doesn't match — super.visitConditionalExpression is called
    await assertNoDiagnostics(r'''
void fn(bool flag, int a, int b) {
  final val = flag ? a : b;
  print(flag ? b : a);
}
''');
  }

  Future<void> test_nonMatchingFunctionExpressionInvocation_noLint() async {
    // FunctionExpressionInvocation that doesn't match — super.visitFunctionExpressionInvocation is called
    await assertNoDiagnostics(r'''
void fn(int Function(int) apply) {
  final result = apply(42);
  print(apply(99));
}
''');
  }

  Future<void> test_nonMatchingCascadeExpression_noLint() async {
    // CascadeExpression that doesn't match — super.visitCascadeExpression is called
    await assertNoDiagnostics(r'''
void fn() {
  final list = []..add(1)..add(2);
  print([]..add(3)..add(4));
}
''');
  }

  Future<void> test_nonMatchingPostfixExpression_noLint() async {
    // PostfixExpression that doesn't match — super.visitPostfixExpression is called
    await assertNoDiagnostics(r'''
void fn(int? a, int? b) {
  final x = a!;
  print(b!);
}
''');
  }

  Future<void> test_nonMatchingPrefixExpression_noLint() async {
    // PrefixExpression that doesn't match — super.visitPrefixExpression is called
    await assertNoDiagnostics(r'''
void fn(List<int> list) {
  final notEmpty = !list.isEmpty;
  print(!list.isNotEmpty);
}
''');
  }

  Future<void> test_nonMatchingAsExpression_noLint() async {
    // AsExpression that doesn't match — super.visitAsExpression is called
    await assertNoDiagnostics(r'''
void fn(dynamic d) {
  final s = d as String;
  print(d as int);
}
''');
  }

  Future<void> test_nonMatchingIsExpression_noLint() async {
    // IsExpression that doesn't match — super.visitIsExpression is called
    await assertNoDiagnostics(r'''
void fn(Object obj) {
  final check = obj is String;
  print(obj is int);
}
''');
  }

  Future<void> test_nonMatchingListLiteral_noLint() async {
    // ListLiteral that doesn't match — super.visitListLiteral is called
    await assertNoDiagnostics(r'''
void fn() {
  const items = [1, 2, 3];
  print([4, 5, 6]);
}
''');
  }

  Future<void> test_nonMatchingSetOrMapLiteral_noLint() async {
    // SetOrMapLiteral that doesn't match — super.visitSetOrMapLiteral is called
    await assertNoDiagnostics(r'''
void fn() {
  const items = {1, 2, 3};
  print({4, 5, 6});
}
''');
  }

  Future<void> test_nonMatchingAwaitExpression_noLint() async {
    // AwaitExpression that doesn't match — super.visitAwaitExpression is called
    await assertNoDiagnostics(r'''
Future<int> getA() async => 1;
Future<int> getB() async => 2;
void fn() async {
  final val = await getA();
  print(await getB());
}
''');
  }

  Future<void> test_nonMatchingParenthesizedExpression_noLint() async {
    // ParenthesizedExpression that doesn't match — super.visitParenthesizedExpression is called
    await assertNoDiagnostics(r'''
void fn(int a, int b) {
  final val = (a + b);
  print((a - b));
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
