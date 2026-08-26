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

  // ---- Positive cases ----

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
    // The `_` spelling is a convention, not the condition. A named parameter
    // nothing reads is the same situation.
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

  // ---- Negative cases ----

  Future<void> test_parameterIsUsed() async {
    // A real dependency on the previous value: `andThen` would discard it.
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> parse(String raw) => throw '';

TaskEither<String, int> f(TaskEither<String, String> pipeline) =>
    pipeline.flatMap((value) => parse(value));
''');
  }

  Future<void> test_nonFpdartFlatMapIsIgnored() async {
    // An unrelated class with a `flatMap` must never be offered an fpdart
    // combinator.
    await assertNoDiagnostics(r'''
class Box<T> {
  Box<R> flatMap<R>(Box<R> Function(T value) f) => throw '';
}

Box<int> next() => throw '';

Box<int> f(Box<String> box) => box.flatMap((_) => next());
''');
  }

  Future<void> test_blockBodyIsIgnored() async {
    // A block body is a real function; narrowing it is not this rule's job.
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
