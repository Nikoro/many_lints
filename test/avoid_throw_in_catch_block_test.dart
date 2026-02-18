import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_throw_in_catch_block.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidThrowInCatchBlockTest),
  );
}

@reflectiveTest
class AvoidThrowInCatchBlockTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidThrowInCatchBlock();
    super.setUp();
  }

  Future<void> test_throwNewExceptionInCatch() async {
    await assertDiagnostics(
      r'''
void f() {
  try {
    print('hello');
  } catch (e) {
    throw Exception('wrapped');
  }
}
''',
      [lint(59, 26)],
    );
  }

  Future<void> test_throwInOnClause() async {
    await assertDiagnostics(
      r'''
void f() {
  try {
    print('hello');
  } on Object {
    throw Exception('wrapped');
  }
}
''',
      [lint(59, 26)],
    );
  }

  Future<void> test_throwCaughtException() async {
    await assertDiagnostics(
      r'''
void f() {
  try {
    print('hello');
  } catch (e) {
    throw e;
  }
}
''',
      [lint(59, 7)],
    );
  }

  Future<void> test_throwStringLiteral() async {
    await assertDiagnostics(
      r'''
void f() {
  try {
    print('hello');
  } catch (e) {
    throw 'error';
  }
}
''',
      [lint(59, 13)],
    );
  }

  Future<void> test_throwInNestedTryCatch() async {
    await assertDiagnostics(
      r'''
void f() {
  try {
    print('hello');
  } catch (e) {
    try {
      print('inner');
    } catch (inner) {
      throw Exception('inner error');
    }
  }
}
''',
      [lint(115, 30)],
    );
  }

  Future<void> test_multipleThrowsInCatch() async {
    await assertDiagnostics(
      r'''
void f() {
  try {
    print('hello');
  } catch (e) {
    if (e is FormatException) {
      throw ArgumentError('bad format');
    }
    throw Exception('unknown');
  }
}
''',
      [lint(93, 33), lint(138, 26)],
    );
  }

  Future<void> test_rethrowIsAllowed() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
    print('hello');
  } catch (e) {
    rethrow;
  }
}
''');
  }

  Future<void> test_noThrowInCatch() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
    print('hello');
  } catch (e, stack) {
    print('$e $stack');
  }
}
''');
  }

  Future<void> test_throwOutsideCatchIsAllowed() async {
    await assertNoDiagnostics(r'''
void f() {
  throw Exception('not in catch');
}
''');
  }

  Future<void> test_throwInClosureInsideCatchIsAllowed() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
    print('hello');
  } catch (e) {
    final callback = () {
      throw Exception('in closure');
    };
    callback();
  }
}
''');
  }

  Future<void> test_throwInLocalFunctionInsideCatchIsAllowed() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
    print('hello');
  } catch (e) {
    void localFunc() {
      throw Exception('in local func');
    }
    localFunc();
  }
}
''');
  }

  Future<void> test_throwWithLogicBeforeIsReported() async {
    await assertDiagnostics(
      r'''
void f() {
  try {
    print('hello');
  } catch (e) {
    print(e);
    throw Exception('after logging');
  }
}
''',
      [lint(73, 32)],
    );
  }

  Future<void> test_throwInOnTypedClauseWithCatch() async {
    await assertDiagnostics(
      r'''
void f() {
  try {
    print('hello');
  } on FormatException catch (e) {
    throw ArgumentError(e.toString());
  }
}
''',
      [lint(78, 33)],
    );
  }

  Future<void> test_catchWithStackTraceAndThrow() async {
    await assertDiagnostics(
      r'''
void f() {
  try {
    print('hello');
  } catch (e, s) {
    print(s);
    throw Exception('error');
  }
}
''',
      [lint(76, 24)],
    );
  }
}
