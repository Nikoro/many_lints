import 'package:many_lints/src/rules/prefer_unit_over_void.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fpdart_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferUnitOverVoidTest));
}

@reflectiveTest
class PreferUnitOverVoidTest extends FpdartRuleTest {
  @override
  void setUp() {
    rule = PreferUnitOverVoid();
    super.setUp();
  }

  Future<void> test_taskEitherOfVoid() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, void> save() => throw '';
''',
      [lint(57, 4)],
    );
  }

  Future<void> test_optionOfVoid() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Option<void> f() => throw '';
''',
      [lint(45, 4)],
    );
  }

  Future<void> test_unitIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, Unit> save() => throw '';
''');
  }

  Future<void> test_plainVoidReturnIsFine() async {
    await assertNoDiagnostics(r'''
void f() {}

Future<void> g() async {}
''');
  }

  Future<void> test_overrideIsSkippedByDefault() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

abstract class Base {
  TaskEither<String, Unit> save();
}

class Impl implements Base {
  @override
  TaskEither<String, Unit> save() => throw '';
}
''');
  }

  Future<void> test_overrideReportedWhenConfigured() async {
    newFile('$testPackageRootPath/many_lints.yaml', '''
rules:
  prefer_unit_over_void:
    ignore_overrides: false
''');

    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

abstract class Base {
  TaskEither<String, void> save();
}

class Impl implements Base {
  @override
  TaskEither<String, void> save() => throw '';
}
''',
      [lint(81, 4), lint(160, 4)],
    );
  }

  Future<void> test_nonFpdartGenericIsFine() async {
    await assertNoDiagnostics(r'''
class Box<T> {}

Box<void> f() => throw '';
''');
  }
}
