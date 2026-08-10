import 'package:many_lints/src/rules/avoid_dollar_outside_do_frame.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fpdart_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidDollarOutsideDoFrameTest),
  );
}

@reflectiveTest
class AvoidDollarOutsideDoFrameTest extends FpdartRuleTest {
  @override
  void setUp() {
    rule = AvoidDollarOutsideDoFrame();
    super.setUp();
  }

  Future<void> test_dollarInsideMapCallback() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(Option<String> o, Option<String> b) =>
    Option.Do(($) => optionOf($(o)).map((value) => $(b)).getOrElse(() => ''));
''',
      [lint(145, 4)],
    );
  }

  Future<void> test_dollarInsideFlatMapCallback() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(Option<String> a, Option<String> b) => Option.Do(($) {
  return $(optionOf($(a)).flatMap((value) => Option.of($(b))));
});
''',
      [lint(165, 4)],
    );
  }

  Future<void> test_dollarInBlockFrameIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(Option<String> a, Option<String> b) => Option.Do(($) {
  final first = $(a);
  final second = $(b);
  return '$first$second';
});
''');
  }

  Future<void> test_dollarInExpressionBodyIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(Option<String> o) => Option.Do(($) => $(o));
''');
  }

  Future<void> test_extractedThenUsedInCallbackIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<Option<String>> f(Option<String> o) => Option.Do(($) {
  final value = $(o);
  return optionOf(value).map((v) => v);
});
''');
  }

  Future<void> test_nestedDoDollarNotAttributedToOuter() async {
    // The inner block's `$` belongs to the inner frame, so the outer block is
    // not blamed for it. The nesting itself is `avoid_nested_do_notation`.
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(Option<String> o) => Option.Do(($) {
  return $(Option.Do(($) => $(o)));
});
''');
  }
}
