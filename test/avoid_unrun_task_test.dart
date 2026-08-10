import 'package:many_lints/src/rules/avoid_unrun_task.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fpdart_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidUnrunTaskTest));
}

@reflectiveTest
class AvoidUnrunTaskTest extends FpdartRuleTest {
  @override
  void setUp() {
    rule = AvoidUnrunTask();
    super.setUp();
  }

  Future<void> test_discardedTaskEither() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> save() => TaskEither.of(1);

void f() {
  save();
}
''',
      [lint(104, 6)],
    );
  }

  Future<void> test_discardedTask() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Task<int> work() => Task.of(1);

void f() {
  work();
}
''',
      [lint(84, 6)],
    );
  }

  Future<void> test_discardedIo() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

IO<int> work() => IO.of(1);

void f() {
  work();
}
''',
      [lint(80, 6)],
    );
  }

  Future<void> test_runCalledIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> save() => TaskEither.of(1);

Future<void> f() async {
  await save().run();
}
''');
  }

  Future<void> test_assignedIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> save() => TaskEither.of(1);

void f() {
  final task = save();
  task.run();
}
''');
  }

  Future<void> test_returnedIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> save() => TaskEither.of(1);

TaskEither<String, int> f() => save();
''');
  }

  Future<void> test_eitherIsNotLazy() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Either<String, int> compute() => Either.of(1);

void f() {
  compute();
}
''');
  }

  Future<void> test_optionIsNotLazy() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<int> compute() => Option.of(1);

void f() {
  compute();
}
''');
  }

  Future<void> test_unrelatedTypeIsFine() async {
    await assertNoDiagnostics(r'''
int compute() => 1;

void f() {
  compute();
}
''');
  }

  Future<void> test_reassignmentIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> save() => TaskEither.of(1);

void f() {
  TaskEither<String, int> task = TaskEither.of(0);
  task = save();
  task.run();
}
''');
  }
}
