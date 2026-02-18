import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_return_await.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferReturnAwaitTest));
}

@reflectiveTest
class PreferReturnAwaitTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferReturnAwait();
    super.setUp();
  }

  // --- Positive cases (should trigger lint) ---

  Future<void> test_returnFutureInTryBody() async {
    await assertDiagnostics(
      r'''
Future<String> f() async {
  try {
    return asyncOp();
  } catch (e) {
    return 'fallback';
  }
}

Future<String> asyncOp() async => 'result';
''',
      [lint(46, 9)],
    );
  }

  Future<void> test_returnFutureInCatchClause() async {
    await assertDiagnostics(
      r'''
Future<String> f() async {
  try {
    throw Exception();
  } catch (e) {
    return asyncOp();
  }
}

Future<String> asyncOp() async => 'result';
''',
      [lint(85, 9)],
    );
  }

  Future<void> test_returnFutureMethodCallInTry() async {
    await assertDiagnostics(
      r'''
class MyClass {
  Future<int> fetch() async {
    try {
      return _load();
    } catch (e) {
      return -1;
    }
  }

  Future<int> _load() async => 42;
}
''',
      [lint(69, 7)],
    );
  }

  Future<void> test_returnFutureInNestedTry() async {
    await assertDiagnostics(
      r'''
Future<String> f() async {
  try {
    try {
      return asyncOp();
    } catch (e) {
      return 'inner';
    }
  } catch (e) {
    return 'outer';
  }
}

Future<String> asyncOp() async => 'result';
''',
      [lint(58, 9)],
    );
  }

  // --- Negative cases (should NOT trigger lint) ---

  Future<void> test_returnAwaitInTry() async {
    await assertNoDiagnostics(r'''
Future<String> f() async {
  try {
    return await asyncOp();
  } catch (e) {
    return 'fallback';
  }
}

Future<String> asyncOp() async => 'result';
''');
  }

  Future<void> test_returnNonFutureInTry() async {
    await assertNoDiagnostics(r'''
Future<String> f() async {
  try {
    return 'hello';
  } catch (e) {
    return 'fallback';
  }
}
''');
  }

  Future<void> test_returnFutureOutsideTryCatch() async {
    await assertNoDiagnostics(r'''
Future<String> f() async {
  return asyncOp();
}

Future<String> asyncOp() async => 'result';
''');
  }

  Future<void> test_returnFutureInNonAsyncFunction() async {
    await assertNoDiagnostics(r'''
Future<String> f() {
  try {
    return asyncOp();
  } catch (e) {
    return Future.value('fallback');
  }
}

Future<String> asyncOp() async => 'result';
''');
  }

  Future<void> test_returnFutureInFinallyBlock() async {
    await assertNoDiagnostics(r'''
Future<String> f() async {
  try {
    return await asyncOp();
  } catch (e) {
    return 'fallback';
  } finally {
    print('done');
  }
}

Future<String> asyncOp() async => 'result';
''');
  }

  Future<void> test_returnWithNoExpression() async {
    await assertNoDiagnostics(r'''
Future<void> f() async {
  try {
    await asyncOp();
    return;
  } catch (e) {
    print(e);
  }
}

Future<void> asyncOp() async {}
''');
  }

  Future<void> test_returnAwaitInCatch() async {
    await assertNoDiagnostics(r'''
Future<String> f() async {
  try {
    throw Exception();
  } catch (e) {
    return await asyncOp();
  }
}

Future<String> asyncOp() async => 'result';
''');
  }

  // --- Edge cases ---

  Future<void> test_returnFutureInNestedAsyncClosure() async {
    // The closure is its own async scope; outer try-catch shouldn't matter
    await assertNoDiagnostics(r'''
void f() {
  try {
    final fn = () async {
      return asyncOp();
    };
    fn();
  } catch (e) {
    print(e);
  }
}

Future<String> asyncOp() async => 'result';
''');
  }

  Future<void> test_returnFutureOrInTry() async {
    await assertDiagnostics(
      r'''
import 'dart:async';

Future<int> f() async {
  try {
    return getFutureOr();
  } catch (e) {
    return -1;
  }
}

FutureOr<int> getFutureOr() => 42;
''',
      [lint(65, 13)],
    );
  }
}
