import 'package:many_lints/src/rule_config.dart';
import 'package:many_lints/src/rules/no_magic_string.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoMagicStringTest);
    defineReflectiveTests(NoMagicStringOccurrencesOptionTest);
  });
}

@reflectiveTest
class NoMagicStringTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = NoMagicString();
    super.setUp();
  }

  Future<void> test_repeatedStringIsReportedAtEveryOccurrence() async {
    await assertDiagnostics(
      r'''
void a() => print('x-request-id');
void b() => print('x-request-id');
void c() => print('x-request-id');
''',
      [lint(18, 14), lint(53, 14), lint(88, 14)],
    );
  }

  Future<void> test_singleOccurrenceIsSilent() async {
    await assertNoDiagnostics(r'''
void a() => print('x-request-id');
''');
  }

  Future<void> test_twoOccurrencesAreBelowTheDefault() async {
    await assertNoDiagnostics(r'''
void a() => print('x-request-id');
void b() => print('x-request-id');
''');
  }

  Future<void> test_shortStringIsSilent() async {
    await assertNoDiagnostics(r'''
void a() => print(', ');
void b() => print(', ');
void c() => print(', ');
''');
  }

  Future<void> test_constDeclarationIsExempt() async {
    await assertNoDiagnostics(r'''
const header = 'x-request-id';
const alias = 'x-request-id';
const spare = 'x-request-id';
''');
  }
}

@reflectiveTest
class NoMagicStringOccurrencesOptionTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = NoMagicString();
    super.setUp();
    ConfigLoader.clearCache();
    newFile(
      '$testPackageRootPath/${ConfigLoader.fileName}',
      'rules:\n'
          '  no_magic_string:\n'
          '    min_occurrences: 2\n',
    );
  }

  Future<void> test_loweredThresholdReports() async {
    await assertDiagnostics(
      r'''
void a() => print('x-request-id');
void b() => print('x-request-id');
''',
      [lint(18, 14), lint(53, 14)],
    );
  }

  Future<void> test_singleOccurrenceIsStillSilent() async {
    await assertNoDiagnostics(r'''
void a() => print('x-request-id');
''');
  }
}
