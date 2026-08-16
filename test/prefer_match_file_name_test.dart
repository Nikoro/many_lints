import 'package:many_lints/src/rules/prefer_match_file_name.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferMatchFileNameTest);
    defineReflectiveTests(PreferMatchFileNameMatchingTest);
  });
}

/// The harness writes `lib/test.dart`, so every declaration here is compared
/// against the base name `test`.
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

  // Only the first public declaration names the file; the rest are not
  // separately fixable.
  Future<void> test_onlyFirstDeclarationReported() async {
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

  // A file with nothing public has no name to match.
  Future<void> test_privateOnlyFileIsSilent() async {
    await assertNoDiagnostics(r'''
class _Hidden {}
''');
  }

  // `main` is an entrypoint, not the file's subject. Every test file declares
  // one and none of them can be named main.dart — this was 143 of 166 reports
  // on a real codebase, all wrong.
  Future<void> test_mainIsNotTheFileSubject() async {
    await assertNoDiagnostics(r'''
void main() {}
''');
  }

  // dart_frog's route contract: the file's PATH is the API, so `onRequest`
  // cannot name it.
  Future<void> test_frameworkEntrypointIsSkipped() async {
    await assertNoDiagnostics(r'''
void onRequest() {}
''');
  }

  // The list is configurable, and an entry that is NOT listed still reports —
  // the asymmetric pair for the option.
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

  // ...but a declaration named `main` that is not a function still counts.
  Future<void> test_mainClassStillReports() async {
    await assertDiagnostics(
      r'''
class Main {}
''',
      [lint(6, 4)],
    );
  }

  // The entrypoint is skipped, not the whole file: a public declaration after
  // it is still the file's subject.
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

/// Renames the analyzed file so its name genuinely matches the declaration —
/// the asymmetric positive the cookbook requires, proving the rule's silence
/// above comes from the match rather than from the rule never running.
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

  // HTTPClient -> http_client, not h_t_t_p_client.
  Future<void> test_acronymSnakeCase() async {
    await assertDiagnostics(
      r'''
class HTTPClient {}
''',
      [lint(6, 10)],
    );
  }
}
