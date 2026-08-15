import 'package:many_lints/src/rules/avoid_unnecessary_call.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidUnnecessaryCallTest));
}

@reflectiveTest
class AvoidUnnecessaryCallTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryCall();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_explicitCallOnParameter() async {
    await assertDiagnostics(
      r'''
void f(void Function() callback) {
  callback.call();
}
''',
      [lint(46, 4)],
    );
  }

  Future<void> test_explicitCallWithArguments() async {
    await assertDiagnostics(
      r'''
void f(void Function(int) callback) {
  callback.call(1);
}
''',
      [lint(49, 4)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_directInvocation() async {
    await assertNoDiagnostics(r'''
void f(void Function() callback) {
  callback();
}
''');
  }

  Future<void> test_nullAwareCallHasNoShorthand() async {
    // `callback?()` does not parse, so `.call` is required here.
    await assertNoDiagnostics(r'''
void f(void Function()? callback) {
  callback?.call();
}
''');
  }

  Future<void> test_callMethodOnACallableClass() async {
    // `Counter` defines `call` as a real method, so `.call` is its name.
    await assertNoDiagnostics(r'''
class Counter {
  int call() => 1;
}

void f(Counter counter) {
  counter.call();
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_unrelatedMethodNamedCall() async {
    await assertNoDiagnostics(r'''
class Api {
  void call(String endpoint) {}
}

void f(Api api) {
  api.call('/users');
}
''');
  }
}
