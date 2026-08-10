import 'package:many_lints/src/rules/avoid_either_of_future.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fpdart_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidEitherOfFutureTest));
}

@reflectiveTest
class AvoidEitherOfFutureTest extends FpdartRuleTest {
  @override
  void setUp() {
    rule = AvoidEitherOfFuture();
    super.setUp();
  }

  Future<void> test_writtenEitherOfFuture() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Either<String, Future<int>> f() => throw '';
''',
      [lint(53, 11)],
    );
  }

  Future<void> test_writtenOptionOfFuture() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Option<Future<int>> f() => throw '';
''',
      [lint(45, 11)],
    );
  }

  Future<void> test_mapReturningFuture() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Future<String> load(int id) async => '';

void f(Either<String, int> either) {
  final result = either.map((id) => load(id));
}
''',
      [lint(141, 3)],
    );
  }

  Future<void> test_optionMapReturningFuture() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Future<String> load(int id) async => '';

void f(Option<int> option) {
  final result = option.map((id) => load(id));
}
''',
      [lint(133, 3)],
    );
  }

  Future<void> test_taskEitherIsFine() async {
    // TaskEither is the async wrapper: a Future belongs inside it.
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> f() => throw '';
''');
  }

  Future<void> test_syncMapIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

void f(Either<String, int> either) {
  final result = either.map((id) => id + 1);
}
''');
  }

  Future<void> test_iterableMapOfFutureIsFine() async {
    await assertNoDiagnostics(r'''
Future<String> load(int id) async => '';

void f(List<int> ids) {
  final result = ids.map((id) => load(id));
}
''');
  }

  Future<void> test_eitherOfNonFutureIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Either<String, List<int>> f() => throw '';
''');
  }

  Future<void> test_toTaskEitherIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> f(Either<String, int> either) =>
    either.toTaskEither();
''');
  }
}
