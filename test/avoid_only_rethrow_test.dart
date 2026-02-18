import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_only_rethrow.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidOnlyRethrowTest));
}

@reflectiveTest
class AvoidOnlyRethrowTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidOnlyRethrow();
    super.setUp();
  }

  Future<void> test_catchOnlyRethrow() async {
    await assertDiagnostics(
      r'''
void f() {
  try {
    print('hello');
  } catch (e) {
    rethrow;
  }
}
''',
      [lint(43, 28)],
    );
  }

  Future<void> test_onClauseOnlyRethrow() async {
    await assertDiagnostics(
      r'''
void f() {
  try {
    print('hello');
  } on Exception {
    rethrow;
  }
}
''',
      [lint(43, 31)],
    );
  }

  Future<void> test_onClauseWithoutCatchOnlyRethrow() async {
    await assertDiagnostics(
      r'''
void f() {
  try {
    print('hello');
  } on FormatException {
    rethrow;
  }
}
''',
      [lint(43, 37)],
    );
  }

  Future<void> test_onObjectOnlyRethrow() async {
    await assertDiagnostics(
      r'''
void f() {
  try {
    print('hello');
  } on Object {
    rethrow;
  }
}
''',
      [lint(43, 28)],
    );
  }

  Future<void> test_catchWithLogicBeforeRethrow() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
    print('hello');
  } catch (e) {
    print(e);
    rethrow;
  }
}
''');
  }

  Future<void> test_catchWithoutRethrow() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
    print('hello');
  } catch (e) {
    print(e);
  }
}
''');
  }

  Future<void> test_emptyBody() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
    print('hello');
  } catch (e) {
  }
}
''');
  }

  Future<void> test_multipleCatchClauses_oneRethrow() async {
    await assertDiagnostics(
      r'''
void f() {
  try {
    print('hello');
  } on FormatException {
    print('format error');
  } on Exception {
    rethrow;
  }
}
''',
      [lint(95, 31)],
    );
  }

  Future<void> test_catchWithFinally() async {
    await assertDiagnostics(
      r'''
void f() {
  try {
    print('hello');
  } catch (e) {
    rethrow;
  } finally {
    print('done');
  }
}
''',
      [lint(43, 28)],
    );
  }

  Future<void> test_catchWithConditionalRethrow() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
    print('hello');
  } catch (e) {
    if (e is FormatException) {
      print(e);
      return;
    }
    rethrow;
  }
}
''');
  }
}
