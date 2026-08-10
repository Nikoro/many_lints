import 'package:many_lints/src/rules/avoid_nested_do_notation.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fpdart_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidNestedDoNotationTest));
}

@reflectiveTest
class AvoidNestedDoNotationTest extends FpdartRuleTest {
  @override
  void setUp() {
    rule = AvoidNestedDoNotation();
    super.setUp();
  }

  Future<void> test_nestedOptionDo() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(Option<String> o) =>
    Option.Do(($) => $(Option.Do(($) => $(o))));
''',
      [lint(99, 9)],
    );
  }

  Future<void> test_nestedTaskEitherDo() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> f(TaskEither<String, int> t) =>
    TaskEither.Do(($) async {
      final inner = await $(TaskEither.Do(($) async => await $(t)));
      return inner;
    });
''',
      [lint(152, 13)],
    );
  }

  Future<void> test_deeplyNestedReportsEachInnerBlock() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(Option<String> o) =>
    Option.Do(($) => $(Option.Do(($) => $(Option.Do(($) => $(o))))));
''',
      [lint(99, 9), lint(118, 9)],
    );
  }

  Future<void> test_siblingDoBlocksAreFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<String> a(Option<String> o) => Option.Do(($) => $(o));
Option<String> b(Option<String> o) => Option.Do(($) => $(o));
''');
  }

  Future<void> test_singleDoIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(Option<String> a, Option<String> b) => Option.Do(($) {
  final first = $(a);
  final second = $(b);
  return '$first$second';
});
''');
  }

  Future<void> test_unrelatedDoConstructorIsIgnored() async {
    await assertNoDiagnostics(r'''
class Builder {
  factory Builder.Do(void Function() f) => Builder();
  Builder();
}

Builder f() => Builder.Do(() {
  Builder.Do(() {});
});
''');
  }
}
