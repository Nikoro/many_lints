import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_nested_futures.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidNestedFuturesTest));
}

@reflectiveTest
class AvoidNestedFuturesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNestedFutures();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_nestedFutureReturnType() async {
    await assertDiagnostics(
      r'''
Future<Future<int>> load() => throw '';
''',
      [lint(0, 19)],
    );
  }

  Future<void> test_nestedFutureFieldType() async {
    await assertDiagnostics(
      r'''
class Holder {
  Future<Future<String>>? pending;
}
''',
      [lint(17, 23)],
    );
  }

  Future<void> test_nestedFutureParameter() async {
    await assertDiagnostics(
      r'''
void accept(Future<Future<int>> value) {}
''',
      [lint(12, 19)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_plainFuture() async {
    await assertNoDiagnostics(r'''
Future<int> load() => throw '';
''');
  }

  Future<void> test_futureOfList() async {
    await assertNoDiagnostics(r'''
Future<List<int>> load() => throw '';
''');
  }

  Future<void> test_listOfFutures() async {
    await assertNoDiagnostics(r'''
List<Future<int>> load() => throw '';
''');
  }

  Future<void> test_futureOfNullableInt() async {
    await assertNoDiagnostics(r'''
Future<int?> load() => throw '';
''');
  }

  Future<void> test_nonFutureGeneric() async {
    await assertNoDiagnostics(r'''
class Box<T> {}

Box<Box<int>> nested() => throw '';
''');
  }
}
