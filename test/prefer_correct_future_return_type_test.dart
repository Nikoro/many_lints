import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:many_lints/src/rules/prefer_correct_future_return_type.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferCorrectFutureReturnTypeTest),
  );
}

@reflectiveTest
class PreferCorrectFutureReturnTypeTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferCorrectFutureReturnType();
    super.setUp();
  }

  Future<void> test_dynamicFunction() async {
    await assertDiagnostics('dynamic load() async => 1;', [lint(0, 7)]);
  }

  Future<void> test_objectMethod() async {
    await assertDiagnostics(
      r'''
class Repository {
  Object load() async => 1;
}
''',
      [lint(21, 6)],
    );
  }

  Future<void> test_futureOr() async {
    await assertDiagnostics(
      r'''
import 'dart:async';

FutureOr<int> load() async => 1;
''',
      [lint(22, 13)],
    );
  }

  Future<void> test_nullableFuture() async {
    await assertDiagnostics('Future<int>? load() async => 1;', [lint(0, 12)]);
  }

  Future<void> test_nullableFutureOr() async {
    await assertDiagnostics(
      r'''
import 'dart:async';

FutureOr<int>? load() async => 1;
''',
      [lint(22, 14)],
    );
  }

  Future<void> test_typeParameter() async {
    await assertDiagnostics('T load<T>(T value) async => value;', [
      error(diag.illegalAsyncReturnType, 0, 1),
    ]);
  }

  Future<void> test_nonNullableFuture() async {
    await assertNoDiagnostics('Future<int> load() async => 1;');
  }

  Future<void> test_voidAsyncCallback() async {
    await assertNoDiagnostics('void handle() async {}');
  }

  Future<void> test_inferredReturnType() async {
    await assertNoDiagnostics('load() async => 1;');
  }

  Future<void> test_asyncGenerator() async {
    await assertNoDiagnostics('Stream<int> load() async* { yield 1; }');
  }

  Future<void> test_synchronousObjectFunction() async {
    await assertNoDiagnostics('Object load() => 1;');
  }
}
