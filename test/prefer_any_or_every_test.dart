import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_any_or_every.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferAnyOrEveryTest));
}

@reflectiveTest
class PreferAnyOrEveryTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferAnyOrEvery();
    super.setUp();
  }

  Future<void> test_whereIsEmpty() async {
    await assertDiagnostics(
      r'''
void f() {
  final list = [1, 2, 3];
  list.where((e) => e > 1).isEmpty;
}
''',
      [lint(39, 32)],
    );
  }

  Future<void> test_whereIsNotEmpty() async {
    await assertDiagnostics(
      r'''
void f() {
  final list = [1, 2, 3];
  list.where((e) => e > 1).isNotEmpty;
}
''',
      [lint(39, 35)],
    );
  }

  Future<void> test_any() async {
    await assertDiagnostics(
      r'''
void f() {
  final list = [1, 2, 3];
  list.any((e) => e > 1);
}
''',
      [
        // any() is not defined on List in the test environment,
        // but the lint rule should not trigger.
        error(diag.undefinedMethod, 44, 3),
      ],
    );
  }

  Future<void> test_every() async {
    await assertDiagnostics(
      r'''
void f() {
  final list = [1, 2, 3];
  list.every((e) => e > 1);
}
''',
      [
        // every() is not defined on List in the test environment,
        // but the lint rule should not trigger.
        error(diag.undefinedMethod, 44, 5),
      ],
    );
  }

  Future<void> test_whereWithLength() async {
    await assertNoDiagnostics(r'''
void f() {
  final list = [1, 2, 3];
  list.where((e) => e > 1).length;
}
''');
  }
}
