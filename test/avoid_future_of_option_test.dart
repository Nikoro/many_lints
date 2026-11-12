import 'package:many_lints/src/rules/avoid_future_of_option.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fpdart_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidFutureOfOptionTest));
}

@reflectiveTest
class AvoidFutureOfOptionTest extends FpdartRuleTest {
  @override
  void setUp() {
    rule = AvoidFutureOfOption();
    super.setUp();
  }

  Future<void> test_functionReturningFutureOfOption() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Future<Option<int>> f() async => throw '';
''',
      [lint(38, 19)],
    );
  }

  Future<void> test_methodReturningFutureOfOption() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

class Repository {
  Future<Option<int>> load() async => throw '';
}
''',
      [lint(59, 19)],
    );
  }

  Future<void> test_taskOptionIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

TaskOption<int> f() => throw '';
''');
  }

  Future<void> test_plainOptionIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<int> f() => throw '';
''');
  }

  Future<void> test_futureOfEitherIsNotThisRule() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Future<Either<String, int>> f() async => throw '';
''');
  }

  Future<void> test_futureOfNonFpdartTypeIsFine() async {
    await assertNoDiagnostics(r'''
Future<int> f() async => 1;
''');
  }

  Future<void> test_optionOfFutureIsNotThisRule() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<Future<int>> f() => throw '';
''');
  }

  Future<void> test_generatorIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Stream<Option<int>> f() async* {
  yield throw '';
}
''');
  }

  Future<void> test_futureOrIsFine() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

import 'package:fpdart/fpdart.dart';

FutureOr<Option<int>> f() => throw '';
''');
  }

  Future<void> test_privateReportedByDefault() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Future<Option<int>> _f() async => throw '';
''',
      [lint(38, 19)],
    );
  }

  Future<void> test_ignorePrivateOption() async {
    newFile('$testPackageRootPath/many_lints.yaml', '''
rules:
  avoid_future_of_option:
    ignore_private: true
''');

    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Future<Option<int>> _f() async => throw '';
''');
  }
}
