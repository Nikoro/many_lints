import 'package:many_lints/src/rules/prefer_from_predicate.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fpdart_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferFromPredicateTest));
}

@reflectiveTest
class PreferFromPredicateTest extends FpdartRuleTest {
  @override
  void setUp() {
    rule = PreferFromPredicate();
    super.setUp();
  }

  Future<void> test_singleConditionPredicate() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Option<int> f(int age) => age > 18 ? Option.of(age) : Option<int>.none();
''',
      [lint(64, 46)],
    );
  }

  Future<void> test_methodCallCondition() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(String name) =>
    name.isNotEmpty ? Option.of(name) : Option<String>.none();
''',
      [lint(75, 57)],
    );
  }

  Future<void> test_fromPredicateIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<int> f(int age) => Option.fromPredicate(age, (a) => a > 18);
''');
  }

  Future<void> test_nullTestIsLeftToFromNullable() async {
    // `prefer_from_nullable` owns this shape and its fix produces better code.
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(String? name) =>
    name != null ? Option.of(name) : Option<String>.none();
''');
  }

  Future<void> test_complexConditionIsFineByDefault() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<int> f(int age) =>
    age > 18 && age < 65 ? Option.of(age) : Option<int>.none();
''');
  }

  Future<void> test_complexConditionReportedWhenConfigured() async {
    newFile('$testPackageRootPath/many_lints.yaml', '''
preset: all
rules:
  prefer_from_predicate:
    max_condition_complexity: 3
''');

    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Option<int> f(int age) =>
    age > 18 && age < 65 ? Option.of(age) : Option<int>.none();
''',
      [lint(68, 58)],
    );
  }

  Future<void> test_conditionOnAnotherValueIsFine() async {
    // The condition tests one thing and wraps another, so this is not a
    // predicate on the wrapped value.
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<int> f(int age, bool enabled) =>
    enabled ? Option.of(age) : Option<int>.none();
''');
  }

  Future<void> test_nonOptionConditionalIsFine() async {
    await assertNoDiagnostics(r'''
int f(int age) => age > 18 ? age : 0;
''');
  }
}
