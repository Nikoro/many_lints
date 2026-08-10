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

  /// `TaskOption` is the point of the rule, so it must never be reported.
  Future<void> test_taskOptionIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

TaskOption<int> f() => throw '';
''');
  }

  /// A synchronous `Either` is a different shape entirely.
  Future<void> test_plainOptionIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<int> f() => throw '';
''');
  }

  /// `Future<Either>` is `avoid_future_of_either`'s job.
  Future<void> test_futureOfEitherIsNotThisRule() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Future<Either<String, int>> f() async => throw '';
''');
  }

  /// A `Future` of anything else is ordinary Dart.
  Future<void> test_futureOfNonFpdartTypeIsFine() async {
    await assertNoDiagnostics(r'''
Future<int> f() async => 1;
''');
  }

  /// `Option<Future<T>>` is the reverse nesting, and is a genuine bug that
  /// `avoid_either_of_future` reports instead. This rule must not double up.
  Future<void> test_optionOfFutureIsNotThisRule() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<Future<int>> f() => throw '';
''');
  }

  /// A generator yields many values; one `TaskOption` cannot replace a stream.
  Future<void> test_generatorIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Stream<Option<int>> f() async* {
  yield throw '';
}
''');
  }

  /// `FutureOr` may complete synchronously, so it is not the same shape.
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
preset: all
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
