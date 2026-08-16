import 'package:many_lints/src/rules/prefer_correct_test_file_name.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferCorrectTestFileNameTest);
    defineReflectiveTests(PreferCorrectTestFileNameOutsideTestDirTest);
    defineReflectiveTests(PreferCorrectTestFileNameCorrectlyNamedTest);
  });
}

/// Relocates the analyzed file into `test/`.
///
/// The harness writes it to `lib/` by default, and this rule's whole subject
/// is the directory the file sits in — so the tests below override the
/// directory rather than the file name.
mixin _InTestDirectory on ManyLintsRuleTest {
  @override
  String get testPackageLibPath => '$testPackageRootPath/test';
}

/// A file under `test/` whose name lacks the `_test.dart` suffix.
@reflectiveTest
class PreferCorrectTestFileNameTest extends ManyLintsRuleTest
    with _InTestDirectory {
  @override
  String get testFileName => 'user_repository_tests.dart';

  @override
  void setUp() {
    rule = PreferCorrectTestFileName();
    super.setUp();
  }

  Future<void> test_fileDeclaringTestsIsReported() async {
    await assertDiagnostics(
      r'''
void test(String name, void Function() body) {}

void main() {
  test('works', () {});
}
''',
      [lint(54, 4)],
    );
  }

  // A helper under test/ that declares no tests is not a test file.
  Future<void> test_fileWithoutTestsIsSilent() async {
    await assertNoDiagnostics(r'''
void main() {
  print('a fixture generator');
}
''');
  }

  Future<void> test_groupAlsoCounts() async {
    await assertDiagnostics(
      r'''
void group(String name, void Function() body) {}

void main() {
  group('a subject', () {});
}
''',
      [lint(55, 4)],
    );
  }
}

/// The asymmetric positive for the directory check: the same file, with the
/// same name and the same tests, must stay silent outside `test/`.
@reflectiveTest
class PreferCorrectTestFileNameOutsideTestDirTest extends ManyLintsRuleTest {
  @override
  String get testFileName => 'user_repository_tests.dart';

  @override
  void setUp() {
    rule = PreferCorrectTestFileName();
    super.setUp();
  }

  Future<void> test_fileInLibIsSilent() async {
    await assertNoDiagnostics(r'''
void test(String name, void Function() body) {}

void main() {
  test('works', () {});
}
''');
  }
}

/// The asymmetric positive for the suffix check.
@reflectiveTest
class PreferCorrectTestFileNameCorrectlyNamedTest extends ManyLintsRuleTest
    with _InTestDirectory {
  @override
  String get testFileName => 'user_repository_test.dart';

  @override
  void setUp() {
    rule = PreferCorrectTestFileName();
    super.setUp();
  }

  Future<void> test_correctlyNamedFileIsSilent() async {
    await assertNoDiagnostics(r'''
void test(String name, void Function() body) {}

void main() {
  test('works', () {});
}
''');
  }
}
