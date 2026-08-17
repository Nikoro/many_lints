import 'package:many_lints/src/rules/avoid_redundant_async.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidRedundantAsyncTest));
}

@reflectiveTest
class AvoidRedundantAsyncTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidRedundantAsync();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_returnsExistingFutureFromBlock() async {
    await assertDiagnostics(
      r'''
Future<int> f(Future<int> value) async {
  return value;
}
''',
      [lint(12, 1)],
    );
  }

  Future<void> test_returnsExistingFutureFromExpressionBody() async {
    await assertDiagnostics(
      r'''
Future<int> f(Future<int> value) async => value;
''',
      [lint(12, 1)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_asyncWithAwait() async {
    await assertNoDiagnostics(r'''
Future<int> f(Future<int> other) async {
  return await other;
}
''');
  }

  Future<void> test_awaitForCountsAsAwaiting() async {
    await assertNoDiagnostics(r'''
Future<int> f(Stream<int> values) async {
  var total = 0;
  await for (final value in values) {
    total += value;
  }
  return total;
}
''');
  }

  Future<void> test_notAsyncAtAll() async {
    await assertNoDiagnostics(r'''
int f() {
  return 1;
}
''');
  }

  Future<void> test_asyncGenerator() async {
    await assertNoDiagnostics(r'''
Stream<int> f() async* {
  yield 1;
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_asyncVoidWouldChangeTheSignature() async {
    // Dropping `async` here turns `Future<void>` into `void`, which is a
    // signature change rather than a cleanup.
    await assertNoDiagnostics(r'''
Future<void> f() async {
  print('x');
}
''');
  }

  Future<void> test_asyncIsRequiredForRawExpressionValue() async {
    await assertNoDiagnostics(r'''
Future<int> f() async => 1;
''');
  }

  Future<void> test_asyncIsRequiredForRawBlockValue() async {
    await assertNoDiagnostics(r'''
Future<int> f() async {
  return 1;
}
''');
  }

  Future<void> test_asyncTurnsThrowIntoAsynchronousError() async {
    await assertNoDiagnostics(r'''
Future<int> f(Future<int> value, bool fail) async {
  if (fail) throw 'failed';
  return value;
}
''');
  }

  Future<void> test_mixedRawAndFutureReturnsAreSkipped() async {
    await assertNoDiagnostics(r'''
Future<int> f(bool cached, Future<int> value) async {
  if (cached) return value;
  return 1;
}
''');
  }

  Future<void> test_blockThatCanFallThroughIsSkipped() async {
    await assertNoDiagnostics(r'''
Future<void> f(bool cached, Future<void> value) async {
  if (cached) return value;
}
''');
  }

  Future<void> test_awaitInsideNestedClosureBelongsToIt() async {
    await assertNoDiagnostics(r'''
Future<int> f(Future<int> other) async {
  final compute = () async => await other;
  return 1;
}
''');
  }
}
