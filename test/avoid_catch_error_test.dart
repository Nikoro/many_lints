import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_catch_error.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidCatchErrorTest));
}

@reflectiveTest
class AvoidCatchErrorTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidCatchError();
    super.setUp();
  }

  // --- Positive cases (should trigger lint) ---

  Future<void> test_catchErrorOnFuture() async {
    await assertDiagnostics(
      r'''
Future<int> load() async => 1;

void f() {
  load().catchError((Object err) => 0);
}
''',
      [lint(52, 10)],
    );
  }

  Future<void> test_catchErrorWithTestArgument() async {
    await assertDiagnostics(
      r'''
Future<int> load() async => 1;

void f() {
  load().catchError((Object err) => 0, test: (Object e) => true);
}
''',
      [lint(52, 10)],
    );
  }

  Future<void> test_catchErrorOnAwaitedChain() async {
    await assertDiagnostics(
      r'''
Future<int> load() async => 1;

Future<int> f() async {
  return await load().then((v) => v).catchError((Object err) => 0);
}
''',
      [lint(93, 10)],
    );
  }

  Future<void> test_catchErrorOnFutureTypedVariable() async {
    await assertDiagnostics(
      r'''
void f(Future<String> pending) {
  pending.catchError((Object err) => '');
}
''',
      [lint(43, 10)],
    );
  }

  // --- Negative cases (should NOT trigger lint) ---

  Future<void> test_tryCatchIsFine() async {
    await assertNoDiagnostics(r'''
Future<int> load() async => 1;

Future<int> f() async {
  try {
    return await load();
  } catch (err) {
    return 0;
  }
}
''');
  }

  Future<void> test_unrelatedCatchErrorMethod() async {
    await assertNoDiagnostics(r'''
class Task {
  void catchError(void Function(Object) handler) {}
}

void f(Task task) {
  task.catchError((Object err) {});
}
''');
  }

  Future<void> test_unrelatedMethodOnFuture() async {
    await assertNoDiagnostics(r'''
Future<int> load() async => 1;

void f() {
  load().then((v) => v);
}
''');
  }

  // --- Edge cases ---

  Future<void> test_catchErrorOnFutureSubtype() async {
    // A user type implementing Future still routes through the same untyped
    // callback, so it is worth reporting.
    await assertDiagnostics(
      r'''
abstract class MyFuture implements Future<int> {}

void f(MyFuture pending) {
  pending.catchError((Object err) => 0);
}
''',
      [lint(88, 10)],
    );
  }

  Future<void> test_catchErrorTearOff() async {
    await assertNoDiagnostics(r'''
Future<int> load() async => 1;

void f() {
  // A tear-off is not an invocation; there is nothing to rewrite here.
  final fn = load().catchError;
  print(fn);
}
''');
  }
}
