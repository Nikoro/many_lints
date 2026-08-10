import 'package:many_lints/src/rules/avoid_throw_in_fp_callback.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fpdart_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidThrowInFpCallbackTest),
  );
}

@reflectiveTest
class AvoidThrowInFpCallbackTest extends FpdartRuleTest {
  @override
  void setUp() {
    rule = AvoidThrowInFpCallback();
    super.setUp();
  }

  Future<void> test_throwInDoBody() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(Option<String> o) => Option.Do(($) {
  if ($(o) == 'test') {
    throw Exception('Error');
  }
  return 'success';
});
''',
      [lint(120, 24)],
    );
  }

  Future<void> test_throwInMapCallback() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Option<int> f(Option<int> o) => o.map((v) {
  if (v < 0) throw Exception('negative');
  return v;
});
''',
      [lint(95, 27)],
    );
  }

  Future<void> test_throwInFlatMapCallback() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> f(TaskEither<String, int> t) =>
    t.flatMap((v) => throw Exception('boom'));
''',
      [lint(115, 23)],
    );
  }

  Future<void> test_unimplementedErrorIsExemptByDefault() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

class UnimplementedError {}

Option<int> f(Option<int> o) => o.map((v) {
  throw UnimplementedError();
});
''');
  }

  Future<void> test_stateErrorIsExemptByDefault() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

class StateError {
  StateError(String message);
}

Option<int> f(Option<int> o) => o.map((v) {
  throw StateError('unreachable');
});
''');
  }

  Future<void> test_throwOutsideFpCallbackIsFine() async {
    await assertNoDiagnostics(r'''
int f(List<int> values) {
  if (values.isEmpty) throw Exception('empty');
  return values.first;
}
''');
  }

  Future<void> test_throwInIterableMapIsFine() async {
    await assertNoDiagnostics(r'''
List<int> f(List<int> values) => values.map((v) {
  if (v < 0) throw Exception('negative');
  return v;
}).toList();
''');
  }

  Future<void> test_returningFailureIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(Option<String> o) => Option.Do(($) {
  final value = $(o);
  return $(value == 'test' ? Option<String>.none() : Option.of('ok'));
});
''');
  }

  Future<void> test_nestedDoBodyThrowNotAttributedToOuter() async {
    // The outer block must not be blamed for the inner block's throw: the
    // inner `Do` is its own frame, and `avoid_nested_do_notation` reports the
    // nesting separately.
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(Option<String> o) => Option.Do(($) {
  return $(Option.Do(($) {
    throw Exception('inner');
  }));
});
''',
      [lint(123, 24)],
    );
  }
}
