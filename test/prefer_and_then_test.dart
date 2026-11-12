import 'package:many_lints/src/rules/prefer_and_then.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fpdart_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferAndThenTest));
}

@reflectiveTest
class PreferAndThenTest extends FpdartRuleTest {
  @override
  void setUp() {
    rule = PreferAndThen();
    super.setUp();
  }

  Future<void> test_underscoreParameterIsIgnored() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> next() => throw '';

TaskEither<String, int> f(TaskEither<String, String> pipeline) =>
    pipeline.flatMap((_) => next());
''',
      [lint(162, 7)],
    );
  }

  Future<void> test_namedButUnusedParameter() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> next() => throw '';

TaskEither<String, int> f(TaskEither<String, String> pipeline) =>
    pipeline.flatMap((value) => next());
''',
      [lint(162, 7)],
    );
  }

  Future<void> test_parameterIsUsed() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> parse(String raw) => throw '';

TaskEither<String, int> f(TaskEither<String, String> pipeline) =>
    pipeline.flatMap((value) => parse(value));
''');
  }

  Future<void> test_nonFpdartFlatMapIsIgnored() async {
    await assertNoDiagnostics(r'''
class Box<T> {
  Box<R> flatMap<R>(Box<R> Function(T value) f) => throw '';
}

Box<int> next() => throw '';

Box<int> f(Box<String> box) => box.flatMap((_) => next());
''');
  }

  Future<void> test_blockBodyIsIgnored() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> next() => throw '';

TaskEither<String, int> f(TaskEither<String, String> pipeline) =>
    pipeline.flatMap((_) {
      return next();
    });
''');
  }
}
