import 'package:many_lints/src/rules/function_always_returns_same_value.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(FunctionAlwaysReturnsSameValueTest),
  );
}

@reflectiveTest
class FunctionAlwaysReturnsSameValueTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = FunctionAlwaysReturnsSameValue();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_everyBranchReturnsTheSameNumber() async {
    await assertDiagnostics(
      r'''
int f(int x) {
  if (x > 0) return 5;
  return 5;
}
''',
      [lint(4, 1)],
    );
  }

  Future<void> test_everyBranchReturnsTheSameBool() async {
    await assertDiagnostics(
      r'''
bool f(int x) {
  if (x > 0) return true;
  if (x < 0) return true;
  return true;
}
''',
      [lint(5, 1)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_branchesReturnDifferentValues() async {
    await assertNoDiagnostics(r'''
int f(int x) {
  if (x > 0) return 1;
  return 2;
}
''');
  }

  Future<void> test_singleReturn() async {
    await assertNoDiagnostics(r'''
int f() {
  return 5;
}
''');
  }

  Future<void> test_returnsAComputedValue() async {
    await assertNoDiagnostics(r'''
int f(int x) {
  if (x > 0) return x;
  return x * 2;
}
''');
  }

  Future<void> test_overrideMayHaveAFixedAnswer() async {
    await assertNoDiagnostics(r'''
class Base {
  bool check(int x) => true;
}

class A extends Base {
  @override
  bool check(int x) {
    if (x > 0) return true;
    return true;
  }
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_protocolCallbackMustReturnAFixedValue() async {
    // `onNotification` has to return `false` on every path to let the
    // notification keep bubbling — the method exists for its side effect.
    await assertNoDiagnostics(r'''
class A {
  bool onNotification(Object notification) {
    if (notification is String) return false;
    doWork();
    return false;
  }

  void doWork() {}
}
''');
  }

  Future<void> test_notificationCallbackRecognisedByShape() async {
    // A protocol callback given a descriptive name is still one. The `bool`
    // is a "handled" signal, so a fixed `false` is the contract being met.
    await assertNoDiagnostics(r'''
class ScrollNotification {}

class A {
  bool _updateVisibility([ScrollNotification? notification]) {
    if (notification == null) return false;
    doWork();
    return false;
  }

  void doWork() {}
}
''');
  }

  Future<void> test_nestedClosureReturnsAreSeparate() async {
    await assertNoDiagnostics(r'''
int f(int x) {
  final compute = () {
    return 5;
  };
  return compute() + x;
}
''');
  }

  Future<void> test_bareReturnCannotBeCompared() async {
    await assertNoDiagnostics(r'''
void f(int x) {
  if (x > 0) return;
  return;
}
''');
  }
}
