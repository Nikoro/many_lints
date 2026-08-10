import 'package:many_lints/src/rules/prefer_string_parse_extensions.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fpdart_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferStringParseExtensionsTest),
  );
}

@reflectiveTest
class PreferStringParseExtensionsTest extends FpdartRuleTest {
  @override
  void setUp() {
    rule = PreferStringParseExtensions();
    super.setUp();
  }

  Future<void> test_intTryParse() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Option<int> f(String input) => Option.fromNullable(int.tryParse(input));
''',
      [lint(69, 40)],
    );
  }

  Future<void> test_doubleTryParse() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Option<double> f(String input) =>
    Option.fromNullable(double.tryParse(input));
''',
      [lint(76, 43)],
    );
  }

  Future<void> test_extensionIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<int> f(String input) => input.toIntOption;
''');
  }

  Future<void> test_fromNullableOfNonParseIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<String> f(String? name) => Option.fromNullable(name);
''');
  }

  Future<void> test_bareTryParseIsFine() async {
    await assertNoDiagnostics(r'''
int? f(String input) => int.tryParse(input);
''');
  }

  Future<void> test_radixArgumentIsFine() async {
    // `radix:` changes what the call does and no extension covers it.
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<int> f(String input) =>
    Option.fromNullable(int.tryParse(input, radix: 16));
''');
  }

  Future<void> test_unrelatedTryParseIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

class Version {
  static Version? tryParse(String input) => null;
}

Option<Version> f(String input) =>
    Option.fromNullable(Version.tryParse(input));
''');
  }

  Future<void> test_additionalParserReported() async {
    newFile('$testPackageRootPath/many_lints.yaml', '''
preset: all
rules:
  prefer_string_parse_extensions:
    additional_parsers:
      - Version
''');

    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

class Version {
  static Version? tryParse(String input) => null;
}

Option<Version> f(String input) =>
    Option.fromNullable(Version.tryParse(input));
''',
      [lint(146, 44)],
    );
  }
}
