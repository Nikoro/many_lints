import 'package:many_lints/src/rules/avoid_bare_await_in_do.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fpdart_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidBareAwaitInDoTest));
}

@reflectiveTest
class AvoidBareAwaitInDoTest extends FpdartRuleTest {
  @override
  void setUp() {
    rule = AvoidBareAwaitInDo();
    super.setUp();
  }

  Future<void> test_bareAwaitInDoBody() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> f(Future<int> future) => TaskEither.Do(($) async {
  await future;
  return 1;
});
''',
      [lint(115, 12)],
    );
  }

  Future<void> test_extractedAwaitIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> f(TaskEither<String, int> t) =>
    TaskEither.Do(($) async {
      final value = await $(t);
      return value;
    });
''');
  }

  Future<void> test_awaitInsideNestedClosureIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> f(Future<int> future) => TaskEither.Do(($) async {
  final fn = () async => await future;
  await $(TaskEither.of(1));
  return 1;
});
''');
  }

  Future<void> test_syncDoBlockIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(Option<String> o) => Option.Do(($) => $(o));
''');
  }

  Future<void> test_awaitOutsideDoIsFine() async {
    await assertNoDiagnostics(r'''
Future<int> f(Future<int> future) async {
  return await future;
}
''');
  }

  Future<void> test_nestedDoAwaitNotAttributedToOuter() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> f(Future<int> future) => TaskEither.Do(($) async {
  return await $(TaskEither.Do(($) async {
    await future;
    return 1;
  }));
});
''',
      [lint(160, 12)],
    );
  }
}
