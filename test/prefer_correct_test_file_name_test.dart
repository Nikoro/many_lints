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

mixin _InTestDirectory on ManyLintsRuleTest {
  @override
  String get testPackageLibPath => '$testPackageRootPath/test';
}

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
