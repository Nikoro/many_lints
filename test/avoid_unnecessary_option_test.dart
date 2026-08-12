import 'package:many_lints/src/rules/avoid_unnecessary_option.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fpdart_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidUnnecessaryOptionTest),
  );
}

@reflectiveTest
class AvoidUnnecessaryOptionTest extends FpdartRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryOption();
    super.setUp();
  }

  Future<void> test_wrappedThenUnwrapped() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

String _f(String? name) {
  final option = Option.fromNullable(name);
  return option.toNullable() ?? 'unknown';
}
''',
      [lint(72, 6)],
    );
  }

  Future<void> test_composedIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

String _f(String? name) {
  final option = Option.fromNullable(name);
  return option.map((n) => n.toUpperCase()).getOrElse(() => 'unknown');
}
''');
  }

  Future<void> test_passedAsValueIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

void _use(Option<String> option) {}

void _f(String? name) {
  final option = Option.fromNullable(name);
  _use(option);
}
''');
  }

  Future<void> test_publicApiIsFineByDefault() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

String f(String? name) {
  final option = Option.fromNullable(name);
  return option.toNullable() ?? 'unknown';
}
''');
  }

  Future<void> test_publicApiReportedWhenConfigured() async {
    newFile('$testPackageRootPath/many_lints.yaml', '''
rules:
  avoid_unnecessary_option:
    ignore_public_api: false
''');

    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

String f(String? name) {
  final option = Option.fromNullable(name);
  return option.toNullable() ?? 'unknown';
}
''',
      [lint(71, 6)],
    );
  }

  Future<void> test_nonOptionLocalIsFine() async {
    await assertNoDiagnostics(r'''
String _f(String? name) {
  final value = name;
  return value ?? 'unknown';
}
''');
  }
}
