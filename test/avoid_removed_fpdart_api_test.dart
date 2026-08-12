// ignore_for_file: implementation_imports
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:many_lints/src/rules/avoid_removed_fpdart_api.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fpdart_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidRemovedFpdartApiTest));
}

@reflectiveTest
class AvoidRemovedFpdartApiTest extends FpdartRuleTest {
  @override
  void setUp() {
    rule = AvoidRemovedFpdartApi();
    super.setUp();
  }

  Future<void> test_tuple2() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

void f() {
  final pair = Tuple2(1, 'a');
}
''',
      [error(diag.undefinedFunction, 64, 6), lint(64, 6)],
    );
  }

  Future<void> test_predicateClass() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

void f() {
  final p = Predicate;
}
''',
      [error(diag.undefinedIdentifier, 61, 9), lint(61, 9)],
    );
  }

  Future<void> test_currentApiIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

void f() {
  final pair = (1, 'a');
  final option = Option.of(1);
}
''');
  }

  Future<void> test_withoutFpdartImportIsFine() async {
    // A project with its own Tuple2, or a plain typo, must not be reported —
    // the removed name resolves to nothing either way.
    await assertDiagnostics(
      r'''
void f() {
  final pair = Tuple2(1, 'a');
}
''',
      [error(diag.undefinedFunction, 26, 6)],
    );
  }

  Future<void> test_localDeclarationIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

class Tuple2<A, B> {
  Tuple2(this.first, this.second);
  final A first;
  final B second;
}

Option<int> f() {
  final pair = Tuple2(1, 'a');
  return Option.of(pair.first);
}
''');
  }

  Future<void> test_additionalRemovedReported() async {
    newFile('$testPackageRootPath/many_lints.yaml', '''
rules:
  avoid_removed_fpdart_api:
    additional_removed:
      - bind
''');

    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Option<int> f(List<int> values) {
  values.bind((v) => [v]);
  return Option.of(1);
}
''',
      [error(diag.undefinedMethod, 81, 4), lint(81, 4)],
    );
  }
}
