import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_missing_completer_stack_trace.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidMissingCompleterStackTraceTest),
  );
}

@reflectiveTest
class AvoidMissingCompleterStackTraceTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidMissingCompleterStackTrace();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_completeErrorWithoutStackTrace() async {
    await assertDiagnostics(
      r'''
import 'dart:async';

void f(Completer<void> completer) {
  try {
    throw 'boom';
  } catch (e, st) {
    print(st);
    completer.completeError(e);
  }
}
''',
      [lint(123, 26)],
    );
  }

  Future<void> test_typedCatchWithStackTrace() async {
    await assertDiagnostics(
      r'''
import 'dart:async';

void f(Completer<int> completer) {
  try {
    throw 'boom';
  } on String catch (e, st) {
    print(st);
    completer.completeError(e);
  }
}
''',
      [lint(132, 26)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_stackTracePassed() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void f(Completer<void> completer) {
  try {
    throw 'boom';
  } catch (e, st) {
    completer.completeError(e, st);
  }
}
''');
  }

  Future<void> test_catchWithoutStackTraceParameter() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void f(Completer<void> completer) {
  try {
    throw 'boom';
  } catch (e) {
    completer.completeError(e);
  }
}
''');
  }

  Future<void> test_outsideCatchBlock() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void f(Completer<void> completer, Object error) {
  completer.completeError(error);
}
''');
  }

  Future<void> test_nonCompleterTarget() async {
    await assertNoDiagnostics(r'''
class NotACompleter {
  void completeError(Object error) {}
}

void f(NotACompleter target) {
  try {
    throw 'boom';
  } catch (e, st) {
    print(st);
    target.completeError(e);
  }
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_closureInsideCatchIsNotCredited() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void f(Completer<void> completer, void Function(void Function()) run) {
  try {
    throw 'boom';
  } catch (e, st) {
    print(st);
    run(() {
      completer.completeError(e);
    });
  }
}
''');
  }

  Future<void> test_completerSubtypeIsMatched() async {
    await assertDiagnostics(
      r'''
import 'dart:async';

class MyCompleter implements Completer<void> {
  @override
  void complete([FutureOr<void>? value]) {}

  @override
  void completeError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> get future => Future<void>.value();

  @override
  bool get isCompleted => false;
}

void f(MyCompleter completer) {
  try {
    throw 'boom';
  } catch (e, st) {
    print(st);
    completer.completeError(e);
  }
}
''',
      [lint(412, 26)],
    );
  }
}
