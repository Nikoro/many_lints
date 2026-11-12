import 'package:many_lints/src/rule_config.dart';
import 'package:many_lints/src/rules/no_magic_number.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoMagicNumberTest);
    defineReflectiveTests(NoMagicNumberAllowedOptionTest);
  });
}

@reflectiveTest
class NoMagicNumberTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = NoMagicNumber();
    super.setUp();
  }

  Future<void> test_magicNumberInComparison() async {
    await assertDiagnostics(
      r'''
bool tooMany(int retries) => retries > 3;
''',
      [lint(39, 1)],
    );
  }

  Future<void> test_defaultAllowedIndexingNumbersAreSilent() async {
    await assertNoDiagnostics(r'''
int f(List<int> xs) => xs.isEmpty ? -1 : xs.length ~/ 2;
''');
  }

  Future<void> test_initialiserIsAlreadyNamed() async {
    await assertNoDiagnostics(r'''
const maxRetries = 3;
''');
  }

  Future<void> test_defaultValueIsAlreadyNamed() async {
    await assertNoDiagnostics(r'''
void f({int timeout = 30}) {}
''');
  }

  Future<void> test_constructorFieldInitialiserIsAlreadyNamed() async {
    await assertNoDiagnostics(r'''
class C {
  const C() : timeout = 30;

  final int timeout;
}
''');
  }

  Future<void> test_insideConstDeclarationIsExempt() async {
    await assertNoDiagnostics(r'''
const timeouts = [15, 30, 60];
''');
  }

  Future<void> test_constConstructorArgumentStillReports() async {
    await assertDiagnostics(
      r'''
class Insets {
  const Insets(this.value);

  final int value;
}

final insets = const Insets(17);
''',
      [lint(94, 2)],
    );
  }

  Future<void> test_messageQuotesTheLiteralAsWritten() async {
    await assertDiagnostics(
      r'''
bool tooMany(int retries) => retries > 3;
''',
      [
        lint(
          39,
          1,
          messageContainsAll: ['The number 3 is used without a name.'],
        ),
      ],
    );
  }

  Future<void> test_annotationArgumentIsExempt() async {
    await assertNoDiagnostics(r'''
class Timeout {
  const Timeout(this.seconds);

  final int seconds;
}

@Timeout(30)
void f() {}
''');
  }
}

@reflectiveTest
class NoMagicNumberAllowedOptionTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = NoMagicNumber();
    super.setUp();
    ConfigLoader.clearCache();
    newFile(
      '$testPackageRootPath/${ConfigLoader.fileName}',
      'rules:\n'
          '  no_magic_number:\n'
          '    allowed: [0, 1, 60]\n',
    );
  }

  Future<void> test_configuredNumberIsSilent() async {
    await assertNoDiagnostics(r'''
int toSeconds(int minutes) => minutes * 60;
''');
  }

  Future<void> test_replacedSetDropsTheDefaults() async {
    await assertDiagnostics(
      r'''
int double_(int x) => x * 2;
''',
      [lint(26, 1)],
    );
  }
}
