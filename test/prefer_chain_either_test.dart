import 'package:many_lints/src/rules/prefer_chain_either.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fpdart_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferChainEitherTest));
}

@reflectiveTest
class PreferChainEitherTest extends FpdartRuleTest {
  @override
  void setUp() {
    rule = PreferChainEither();
    super.setUp();
  }

  Future<void> test_expressionBodyLift() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Either<String, int> decode(String body) => throw '';

TaskEither<String, int> f(TaskEither<String, String> pipeline) =>
    pipeline.flatMap((body) => decode(body).toTaskEither());
''',
      [lint(171, 7)],
    );
  }

  Future<void> test_blockBodyLift() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Either<String, int> decode(String body) => throw '';

TaskEither<String, int> f(TaskEither<String, String> pipeline) =>
    pipeline.flatMap((body) {
      return decode(body).toTaskEither();
    });
''',
      [lint(171, 7)],
    );
  }

  Future<void> test_chainEitherIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Either<String, int> decode(String body) => throw '';

TaskEither<String, int> f(TaskEither<String, String> pipeline) =>
    pipeline.chainEither(decode);
''');
  }

  Future<void> test_genuineTaskEitherStepIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> load(String body) => throw '';

TaskEither<String, int> f(TaskEither<String, String> pipeline) =>
    pipeline.flatMap(load);
''');
  }

  Future<void> test_callbackDoingMoreIsFine() async {
    // The callback has a second statement, so rewriting to `chainEither`
    // would drop it.
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Either<String, int> decode(String body) => throw '';
void log(String message) {}

TaskEither<String, int> f(TaskEither<String, String> pipeline) =>
    pipeline.flatMap((body) {
      log(body);
      return decode(body).toTaskEither();
    });
''');
  }

  Future<void> test_eitherFlatMapIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Either<String, int> decode(String body) => throw '';

Either<String, int> f(Either<String, String> either) =>
    either.flatMap(decode);
''');
  }
}
