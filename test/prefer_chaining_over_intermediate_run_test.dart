import 'package:many_lints/src/rules/prefer_chaining_over_intermediate_run.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fpdart_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferChainingOverIntermediateRunTest),
  );
}

@reflectiveTest
class PreferChainingOverIntermediateRunTest extends FpdartRuleTest {
  @override
  void setUp() {
    rule = PreferChainingOverIntermediateRun();
    super.setUp();
  }

  Future<void> test_twoRunCallsInOneBody() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> area() => TaskEither.of(1);
TaskEither<String, int> deal(int id) => TaskEither.of(2);

Future<void> best() async {
  final a = await area().run();
  final d = await deal(1).run();
}
''',
      [lint(162, 4)],
    );
  }

  Future<void> test_singleRunIsFine() async {
    // One `.run()` is the boundary the pipeline is meant to have.
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> area() => TaskEither.of(1);

Future<void> best() async {
  final a = await area().run();
}
''');
  }

  Future<void> test_chainedPipelineIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> area() => TaskEither.of(1);
TaskEither<String, int> deal(int id) => TaskEither.of(2);

Future<void> best() async {
  final result = await area().flatMap(deal).run();
}
''');
  }

  Future<void> test_runInsideClosureIsNotCounted() async {
    // The closure has its own boundary; counting it against the enclosing
    // member would report a body that is already correct.
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> area() => TaskEither.of(1);

Future<void> best() async {
  final a = await area().run();
  final handler = () async => await area().run();
}
''');
  }

  Future<void> test_minSequenceWidens() async {
    newFile('$testPackageRootPath/many_lints.yaml', '''
rules:
  prefer_chaining_over_intermediate_run:
    min_sequence: 1
''');

    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> area() => TaskEither.of(1);

Future<void> best() async {
  final a = await area().run();
}
''',
      [lint(104, 4)],
    );
  }

  Future<void> test_minSequenceNarrows() async {
    newFile('$testPackageRootPath/many_lints.yaml', '''
rules:
  prefer_chaining_over_intermediate_run:
    min_sequence: 3
''');

    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> area() => TaskEither.of(1);
TaskEither<String, int> deal(int id) => TaskEither.of(2);

Future<void> best() async {
  final a = await area().run();
  final d = await deal(1).run();
}
''');
  }

  Future<void> test_nonFpdartRunIsFine() async {
    await assertNoDiagnostics(r'''
class Job {
  int run() => 1;
}

void f(Job a, Job b) {
  a.run();
  b.run();
}
''');
  }
}
