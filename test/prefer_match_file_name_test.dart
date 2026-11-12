import 'package:many_lints/src/rules/prefer_match_file_name.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferMatchFileNameTest);
    defineReflectiveTests(PreferMatchFileNameMatchingTest);
  });
}

@reflectiveTest
class PreferMatchFileNameTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferMatchFileName();
    super.setUp();
  }

  Future<void> test_classNameDoesNotMatchFileName() async {
    await assertDiagnostics(
      r'''
class UserRepository {}
''',
      [lint(6, 14)],
    );
  }

  Future<void> test_onlyFirstPublicDeclarationReported() async {
    await assertDiagnostics(
      r'''
class UserRepository {}
class AnotherThing {}
''',
      [lint(6, 14)],
    );
  }

  Future<void> test_privateDeclarationIsSkipped() async {
    await assertDiagnostics(
      r'''
class _Hidden {}
class UserRepository {}
''',
      [lint(23, 14)],
    );
  }

  Future<void> test_privateOnlyFileIsSilent() async {
    await assertNoDiagnostics(r'''
class _Hidden {}
''');
  }

  Future<void> test_mainIsNotTheFileSubject() async {
    await assertNoDiagnostics(r'''
void main() {}
''');
  }

  Future<void> test_dartFrogRouteEntrypointIsSkipped() async {
    await assertNoDiagnostics(r'''
void onRequest() {}
''');
  }

  Future<void> test_entrypointsOptionNarrowsTheList() async {
    newFile(
      '$testPackageRootPath/many_lints.yaml',
      'rules:\n'
          '  prefer_match_file_name:\n'
          '    entrypoints: [main]\n',
    );

    await assertDiagnostics(
      r'''
void onRequest() {}
''',
      [lint(5, 9)],
    );
  }

  Future<void> test_mainClassStillReports() async {
    await assertDiagnostics(
      r'''
class Main {}
''',
      [lint(6, 4)],
    );
  }

  Future<void> test_declarationAfterMainStillReports() async {
    await assertDiagnostics(
      r'''
void main() {}

class UserRepository {}
''',
      [lint(22, 14)],
    );
  }

  Future<void> test_ignoredSuffixIsSkipped() async {
    newFile(
      '$testPackageRootPath/many_lints.yaml',
      'rules:\n'
          '  prefer_match_file_name:\n'
          '    ignored_suffixes: [test.dart]\n',
    );

    await assertNoDiagnostics(r'''
class UserRepository {}
''');
  }
}

@reflectiveTest
class PreferMatchFileNameMatchingTest extends ManyLintsRuleTest {
  @override
  String get testFileName => 'user_repository.dart';

  @override
  void setUp() {
    rule = PreferMatchFileName();
    super.setUp();
  }

  Future<void> test_matchingNameIsSilent() async {
    await assertNoDiagnostics(r'''
class UserRepository {}
''');
  }

  Future<void> test_nonMatchingNameStillReports() async {
    await assertDiagnostics(
      r'''
class SomethingElse {}
''',
      [lint(6, 13)],
    );
  }

  Future<void> test_acronymBecomesOneSnakeCaseWord() async {
    await assertDiagnostics(
      r'''
class HTTPClient {}
''',
      [lint(6, 10)],
    );
  }
}
