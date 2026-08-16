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

  // -1, 0, 1 and 2 are the vocabulary of indexing and counting.
  Future<void> test_allowedNumbersAreSilent() async {
    await assertNoDiagnostics(r'''
int f(List<int> xs) => xs.isEmpty ? -1 : xs.length ~/ 2;
''');
  }

  // A literal initialising a declaration is already named — this is the shape
  // the rule asks people to move towards, so reporting it would be circular.
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

  // A const CONSTRUCTOR call is not a definition: `const EdgeInsets.all(17)`
  // still hides what 17 means.
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

  // The diagnostic quotes the literal as WRITTEN. Comparison normalises to
  // double so `17` and `17.0` match one `allowed:` entry, but reporting the
  // normalised form would name a `17.0` the file does not contain.
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

/// The `allowed` option, with the asymmetric pair the cookbook requires.
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

  // 2 is in the built-in defaults but NOT in the configured list, so replacing
  // the set must make it report — proving `allowed:` replaces rather than adds.
  Future<void> test_replacedSetDropsTheDefaults() async {
    await assertDiagnostics(
      r'''
int double_(int x) => x * 2;
''',
      [lint(26, 1)],
    );
  }
}
