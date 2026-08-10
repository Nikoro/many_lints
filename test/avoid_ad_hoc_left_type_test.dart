import 'package:many_lints/src/rules/avoid_ad_hoc_left_type.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fpdart_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidAdHocLeftTypeTest));
}

@reflectiveTest
class AvoidAdHocLeftTypeTest extends FpdartRuleTest {
  @override
  void setUp() {
    rule = AvoidAdHocLeftType();
    super.setUp();
  }

  /// Writes the config that switches this policy rule on.
  void _configure({String extra = ''}) {
    newFile('$testPackageRootPath/many_lints.yaml', '''
preset: all
rules:
  avoid_ad_hoc_left_type:
    error_types:
      - Failure
$extra
''');
  }

  Future<void> test_silentWithoutConfiguration() async {
    // The control: unconfigured, the rule reports nothing at all.
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> load() => throw '';
''');
  }

  Future<void> test_stringLeftReported() async {
    _configure();

    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

class Failure {}

TaskEither<String, int> load() => throw '';
''',
      [lint(67, 6)],
    );
  }

  Future<void> test_eitherLeftReported() async {
    _configure();

    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

class Failure {}

Either<int, String> parse() => throw '';
''',
      [lint(63, 3)],
    );
  }

  Future<void> test_configuredTypeIsFine() async {
    _configure();

    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

class Failure {}

TaskEither<Failure, int> load() => throw '';
''');
  }

  Future<void> test_subtypeAllowedByDefault() async {
    _configure();

    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

sealed class Failure {}
class NetworkFailure extends Failure {}

TaskEither<NetworkFailure, int> load() => throw '';
''');
  }

  Future<void> test_subtypeReportedWhenDisallowed() async {
    _configure(extra: '    allow_subtypes: false');

    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

sealed class Failure {}
class NetworkFailure extends Failure {}

TaskEither<NetworkFailure, int> load() => throw '';
''',
      [lint(114, 14)],
    );
  }

  Future<void> test_optionHasNoErrorChannel() async {
    _configure();

    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

class Failure {}

Option<String> f() => throw '';
''');
  }

  Future<void> test_nonFpdartGenericIsFine() async {
    _configure();

    await assertNoDiagnostics(r'''
class Failure {}

class Pair<A, B> {}

Pair<String, int> f() => throw '';
''');
  }
}
