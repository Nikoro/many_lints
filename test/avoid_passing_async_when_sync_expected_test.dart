import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_passing_async_when_sync_expected.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidPassingAsyncWhenSyncExpectedTest),
  );
}

@reflectiveTest
class AvoidPassingAsyncWhenSyncExpectedTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidPassingAsyncWhenSyncExpected();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_asyncPassedWhereVoidExpected() async {
    await assertDiagnostics(
      r'''
void schedule(void Function() task) {}

Future<void> save() async {}

void f() {
  schedule(() async {
    await save();
  });
}
''',
      [lint(92, 32)],
    );
  }

  Future<void> test_asyncPassedToNamedVoidParameter() async {
    await assertDiagnostics(
      r'''
void schedule({required void Function() task}) {}

Future<void> save() async {}

void f() {
  schedule(task: () async {
    await save();
  });
}
''',
      [lint(109, 32)],
    );
  }

  Future<void> test_asyncArrowBody() async {
    await assertDiagnostics(
      r'''
void schedule(void Function() task) {}

Future<void> save() async {}

void f() {
  schedule(() async => save());
}
''',
      [lint(92, 18)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_futureReturningParameter() async {
    await assertNoDiagnostics(r'''
void schedule(Future<void> Function() task) {}

Future<void> save() async {}

void f() {
  schedule(() async {
    await save();
  });
}
''');
  }

  Future<void> test_syncCallbackIsFine() async {
    await assertNoDiagnostics(r'''
void schedule(void Function() task) {}

void f() {
  schedule(() {});
}
''');
  }

  Future<void> test_dynamicReturnAcceptsTheFuture() async {
    await assertNoDiagnostics(r'''
void schedule(dynamic Function() task) {}

Future<void> save() async {}

void f() {
  schedule(() async {
    await save();
  });
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_asyncGeneratorIsIgnored() async {
    await assertNoDiagnostics(r'''
void schedule(Stream<int> Function() task) {}

void f() {
  schedule(() async* {
    yield 1;
  });
}
''');
  }

  Future<void> test_closureAssignedToVariableIsIgnored() async {
    await assertNoDiagnostics(r'''
Future<void> save() async {}

void f() {
  final void Function() task = () async {
    await save();
  };
  task();
}
''');
  }

  Future<void> test_nonFunctionParameterIsIgnored() async {
    await assertNoDiagnostics(r'''
void schedule(Object task) {}

void f() {
  schedule(1);
}
''');
  }
}
