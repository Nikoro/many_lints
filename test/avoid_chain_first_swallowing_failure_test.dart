import 'package:many_lints/src/rule_config.dart';
import 'package:many_lints/src/rules/avoid_chain_first_swallowing_failure.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fpdart_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidChainFirstSwallowingFailureTest),
  );
}

@reflectiveTest
class AvoidChainFirstSwallowingFailureTest extends FpdartRuleTest {
  @override
  void setUp() {
    rule = AvoidChainFirstSwallowingFailure();
    super.setUp();
  }

  static const _taskEitherSource = r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, Unit> save(int value) => throw '';

TaskEither<String, int> f(TaskEither<String, int> p) => p.chainFirst(save);
''';

  Future<void> test_taskEitherTearOff() async {
    await assertDiagnostics(_taskEitherSource, [lint(151, 10)]);
  }

  Future<void> test_taskEitherLambda() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, Unit> save(int value) => throw '';

TaskEither<String, int> f(TaskEither<String, int> p) =>
    p.chainFirst((value) => save(value));
''',
      [lint(155, 10)],
    );
  }

  Future<void> test_eitherChainFirst() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Either<String, Unit> check(int value) => throw '';

Either<String, int> f(Either<String, int> p) => p.chainFirst(check);
''',
      [lint(140, 10)],
    );
  }

  Future<void> test_ioEitherChainFirst() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

IOEither<String, Unit> log(int value) => throw '';

IOEither<String, int> f(IOEither<String, int> p) => p.chainFirst(log);
''',
      [lint(144, 10)],
    );
  }

  Future<void> test_flatMapKeepingValueIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, Unit> save(int value) => throw '';

TaskEither<String, int> f(TaskEither<String, int> p) =>
    p.flatMap((value) => save(value).map((_) => value));
''');
  }

  Future<void> test_unrelatedChainFirstIsFine() async {
    await assertNoDiagnostics(r'''
class Box {
  Box chainFirst(Box Function(int) f) => this;
}

Box f(Box box) => box.chainFirst((_) => box);
''');
  }

  Future<void> test_skippedUnderTestByDefault() async {
    final path = '$testPackageRootPath/test/pipeline_test.dart';
    newFile(path, _taskEitherSource);

    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_reportedUnderTestWhenIgnoreTestsIsOff() async {
    ConfigLoader.clearCache();
    newFile(
      '$testPackageRootPath/${ConfigLoader.fileName}',
      'rules:\n'
          '  avoid_chain_first_swallowing_failure:\n'
          '    ignore_tests: false\n',
    );
    final path = '$testPackageRootPath/test/pipeline_test.dart';
    newFile(path, _taskEitherSource);

    await assertDiagnosticsInFile(path, [lint(151, 10)]);
  }
}
