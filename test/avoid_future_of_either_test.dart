import 'package:many_lints/src/rules/avoid_future_of_either.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fpdart_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidFutureOfEitherTest));
}

@reflectiveTest
class AvoidFutureOfEitherTest extends FpdartRuleTest {
  @override
  void setUp() {
    rule = AvoidFutureOfEither();
    super.setUp();
  }

  Future<void> test_functionReturningFutureOfEither() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Future<Either<String, int>> f() async => throw '';
''',
      [lint(38, 27)],
    );
  }

  Future<void> test_methodReturningFutureOfEither() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

class Repository {
  Future<Either<String, int>> load() async => throw '';
}
''',
      [lint(59, 27)],
    );
  }

  Future<void> test_taskEitherIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> f() => throw '';
''');
  }

  Future<void> test_plainEitherIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Either<String, int> f() => throw '';
''');
  }

  Future<void> test_futureOfOptionIsNotThisRule() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Future<Option<int>> f() async => throw '';
''');
  }

  Future<void> test_futureOfNonFpdartTypeIsFine() async {
    await assertNoDiagnostics(r'''
Future<int> f() async => 1;
''');
  }

  Future<void> test_eitherOfFutureIsNotThisRule() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Either<String, Future<int>> f() => throw '';
''');
  }

  Future<void> test_generatorIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Stream<Either<String, int>> f() async* {
  yield throw '';
}
''');
  }

  Future<void> test_futureOrIsFine() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

import 'package:fpdart/fpdart.dart';

FutureOr<Either<String, int>> f() => throw '';
''');
  }

  Future<void> test_privateReportedByDefault() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Future<Either<String, int>> _f() async => throw '';
''',
      [lint(38, 27)],
    );
  }

  Future<void> test_ignorePrivateOption() async {
    newFile('$testPackageRootPath/many_lints.yaml', '''
rules:
  avoid_future_of_either:
    ignore_private: true
''');

    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Future<Either<String, int>> _f() async => throw '';
''');
  }
}
