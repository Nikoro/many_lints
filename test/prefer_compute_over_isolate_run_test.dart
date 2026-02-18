import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_compute_over_isolate_run.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferComputeOverIsolateRunTest),
  );
}

@reflectiveTest
class PreferComputeOverIsolateRunTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferComputeOverIsolateRun();
    super.setUp();
  }

  // --- Positive cases (should trigger lint) ---

  Future<void> test_isolateRunWithClosure() async {
    await assertDiagnostics(
      r'''
import 'dart:isolate';

void fn() async {
  final result = await Isolate.run(() => 42);
}
''',
      [lint(65, 21), error(diag.undefinedMethod, 73, 3)],
    );
  }

  Future<void> test_isolateRunWithAsyncClosure() async {
    await assertDiagnostics(
      r'''
import 'dart:isolate';

void fn() async {
  final result = await Isolate.run(() async => 42);
}
''',
      [lint(65, 27), error(diag.undefinedMethod, 73, 3)],
    );
  }

  Future<void> test_isolateRunWithFunctionReference() async {
    await assertDiagnostics(
      r'''
import 'dart:isolate';

int expensiveWork() => 42;

void fn() async {
  final result = await Isolate.run(expensiveWork);
}
''',
      [lint(93, 26), error(diag.undefinedMethod, 101, 3)],
    );
  }

  Future<void> test_isolateRunWithTypeArgument() async {
    await assertDiagnostics(
      r'''
import 'dart:isolate';

void fn() async {
  final result = await Isolate.run<int>(() => 42);
}
''',
      [lint(65, 26), error(diag.undefinedMethod, 73, 3)],
    );
  }

  Future<void> test_isolateRunWithoutAwait() async {
    await assertDiagnostics(
      r'''
import 'dart:isolate';

void fn() {
  final future = Isolate.run(() => 42);
}
''',
      [lint(53, 21), error(diag.undefinedMethod, 61, 3)],
    );
  }

  // --- Negative cases (should NOT trigger lint) ---

  Future<void> test_computeCall() async {
    await assertNoDiagnostics(r'''
void fn() async {
  // compute is fine
}
''');
  }

  Future<void> test_nonIsolateRun() async {
    await assertNoDiagnostics(r'''
class MyClass {
  static Future<int> run(int Function() callback) async {
    return callback();
  }
}

void fn() async {
  final result = await MyClass.run(() => 42);
}
''');
  }

  Future<void> test_isolateSpawn() async {
    await assertDiagnostics(
      r'''
import 'dart:isolate';

void fn() async {
  await Isolate.spawn((_) {}, null);
}
''',
      [error(diag.undefinedMethod, 58, 5)],
    );
  }

  Future<void> test_localRunMethod() async {
    await assertNoDiagnostics(r'''
class Isolate {
  static Future<int> run(int Function() callback) async {
    return callback();
  }
}

void fn() async {
  final result = await Isolate.run(() => 42);
}
''');
  }
}
