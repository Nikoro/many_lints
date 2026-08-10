import 'package:many_lints/src/rules/avoid_untyped_safe_cast.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fpdart_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidUntypedSafeCastTest));
}

@reflectiveTest
class AvoidUntypedSafeCastTest extends FpdartRuleTest {
  @override
  void setUp() {
    rule = AvoidUntypedSafeCast();
    super.setUp();
  }

  Future<void> test_eitherSafeCastWithoutTypeArguments() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

void f(dynamic json) {
  final result = Either.safeCast(json, (v) => 'not a map');
}
''',
      [lint(78, 15)],
    );
  }

  Future<void> test_optionSafeCastWithoutTypeArguments() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

void f(dynamic json) {
  final result = Option.safeCast(json);
}
''',
      [lint(78, 15)],
    );
  }

  Future<void> test_safeCastStrictWithoutTypeArguments() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

void f(dynamic json) {
  final result = Either.safeCastStrict(json, (v) => 'nope');
}
''',
      [lint(85, 14)],
    );
  }

  Future<void> test_explicitTypeArgumentsAreFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

void f(dynamic json) {
  final result = Either<String, int>.safeCast(json, (v) => 'not an int');
}
''');
  }

  Future<void> test_explicitOptionTypeArgumentIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

void f(dynamic json) {
  final result = Option<int>.safeCast(json);
}
''');
  }

  Future<void> test_contextSuppliedTypeIsFine() async {
    // The binding's type annotation constrains inference, so `R` is `int`
    // rather than `dynamic` and the cast really can fail. Reporting here
    // would be a false positive.
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

void f(dynamic json) {
  final Either<String, int> result = Either.safeCast(json, (v) => 'nope');
}
''');
  }

  Future<void> test_returnTypeSuppliesTypeIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Either<String, int> f(dynamic json) =>
    Either.safeCast(json, (v) => 'nope');
''');
  }

  Future<void> test_explicitStrictTypeArgumentsAreFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

void f(Object json) {
  final result =
      Either.safeCastStrict<String, int, Object>(json, (v) => 'nope');
}
''');
  }

  Future<void> test_unrelatedSafeCastIsFine() async {
    await assertNoDiagnostics(r'''
class Caster {
  static dynamic safeCast(dynamic value) => value;
}

void f(dynamic json) {
  final result = Caster.safeCast(json);
}
''');
  }
}
