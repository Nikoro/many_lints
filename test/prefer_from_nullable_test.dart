import 'package:many_lints/src/rules/prefer_from_nullable.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fpdart_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferFromNullableTest));
}

@reflectiveTest
class PreferFromNullableTest extends FpdartRuleTest {
  @override
  void setUp() {
    rule = PreferFromNullable();
    super.setUp();
  }

  Future<void> test_notEqualNullConditional() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(String? name) =>
    name != null ? Option.of(name) : Option<String>.none();
''',
      [lint(76, 54)],
    );
  }

  Future<void> test_equalNullConditionalSwapsBranches() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(String? name) =>
    name == null ? Option<String>.none() : Option.of(name);
''',
      [lint(76, 54)],
    );
  }

  Future<void> test_nullOnTheLeft() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(String? name) =>
    null != name ? Option.of(name) : Option<String>.none();
''',
      [lint(76, 54)],
    );
  }

  Future<void> test_fromNullableIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(String? name) => Option.fromNullable(name);
''');
  }

  Future<void> test_differentValueWrappedIsFine() async {
    // The `Some` branch wraps a different value than the condition tested, so
    // this conditional is not a `fromNullable` in disguise. Rewriting it would
    // change behaviour.
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(String? name, String other) =>
    name != null ? Option.of(other) : Option<String>.none();
''');
  }

  Future<void> test_nonOptionConditionalIsFine() async {
    await assertNoDiagnostics(r'''
String f(String? name) => name != null ? name : 'fallback';
''');
  }

  Future<void> test_nonNullConditionIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(String name) =>
    name.isNotEmpty ? Option.of(name) : Option<String>.none();
''');
  }

  Future<void> test_someBranchNotOptionIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(String? name, Option<String> fallback) =>
    name != null ? fallback : Option<String>.none();
''');
  }
}
