import 'package:many_lints/src/rules/avoid_get_or_else_swallowing_failure.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fpdart_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidGetOrElseSwallowingFailureTest),
  );
}

@reflectiveTest
class AvoidGetOrElseSwallowingFailureTest extends FpdartRuleTest {
  @override
  void setUp() {
    rule = AvoidGetOrElseSwallowingFailure();
    super.setUp();
  }

  Future<void> test_wildcardParameterDiscardsFailure() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

int f(Either<String, int> result) => result.getOrElse((_) => 0);
''',
      [lint(82, 9)],
    );
  }

  Future<void> test_namedButUnusedParameterDiscardsFailure() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

int f(Either<String, int> result) => result.getOrElse((failure) => 0);
''',
      [lint(82, 9)],
    );
  }

  Future<void> test_usedParameterIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

int f(Either<String, int> result) =>
    result.getOrElse((failure) => failure.length);
''');
  }

  Future<void> test_optionGetOrElseIsFine() async {
    // Option.getOrElse takes no parameter, so there is no failure to discard.
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

int f(Option<int> option) => option.getOrElse(() => 0);
''');
  }

  Future<void> test_matchIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

int f(Either<String, int> result) =>
    result.match((failure) => failure.length, (value) => value);
''');
  }

  Future<void> test_unrelatedGetOrElseIsFine() async {
    await assertNoDiagnostics(r'''
class Box {
  int getOrElse(int Function(String) orElse) => 0;
}

int f(Box box) => box.getOrElse((_) => 0);
''');
  }
}
