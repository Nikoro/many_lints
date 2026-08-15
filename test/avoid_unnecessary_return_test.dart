import 'package:many_lints/src/rules/avoid_unnecessary_return.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidUnnecessaryReturnTest),
  );
}

@reflectiveTest
class AvoidUnnecessaryReturnTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryReturn();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_trailingReturnInVoidFunction() async {
    await assertDiagnostics(
      r'''
void f(int x) {
  print(x);
  return;
}
''',
      [lint(30, 7)],
    );
  }

  Future<void> test_trailingReturnInVoidMethod() async {
    await assertDiagnostics(
      r'''
class A {
  void f(int x) {
    print(x);
    return;
  }
}
''',
      [lint(46, 7)],
    );
  }

  Future<void> test_trailingReturnInFutureVoid() async {
    await assertDiagnostics(
      r'''
Future<void> f(int x) async {
  print(x);
  return;
}
''',
      [lint(44, 7)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_earlyReturnSkipsStatements() async {
    await assertNoDiagnostics(r'''
void f(int x) {
  if (x < 0) return;
  print(x);
}
''');
  }

  Future<void> test_returnWithValue() async {
    await assertNoDiagnostics(r'''
int f(int x) {
  return x;
}
''');
  }

  Future<void> test_noReturnAtAll() async {
    await assertNoDiagnostics(r'''
void f(int x) {
  print(x);
}
''');
  }

  Future<void> test_nonVoidReturnType() async {
    await assertNoDiagnostics(r'''
Future<int> f(int x) async {
  return x;
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_omittedReturnTypeIsNotVoid() async {
    // An omitted type means `dynamic`, where `return;` may be deliberate.
    await assertNoDiagnostics(r'''
f(int x) {
  print(x);
  return;
}
''');
  }

  Future<void> test_returnInsideNestedBlockIsNotLast() async {
    await assertNoDiagnostics(r'''
void f(int x) {
  if (x > 0) {
    return;
  }
  print(x);
}
''');
  }
}
