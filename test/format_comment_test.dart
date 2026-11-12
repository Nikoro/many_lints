import 'package:many_lints/src/rule_config.dart';
import 'package:many_lints/src/rules/format_comment.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FormatCommentTest);
    defineReflectiveTests(FormatCommentRegularCommentsTest);
  });
}

@reflectiveTest
class FormatCommentTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = FormatComment();
    super.setUp();
  }

  Future<void> test_docCommentNotCapitalised() async {
    await assertDiagnostics(
      r'''
/// a user of the system.
class User {}
''',
      [lint(0, 25)],
    );
  }

  Future<void> test_docCommentWithoutPeriod() async {
    await assertDiagnostics(
      r'''
/// A user of the system
class User {}
''',
      [lint(0, 24)],
    );
  }

  Future<void> test_wellFormedDocComment() async {
    await assertNoDiagnostics(r'''
/// A user of the system.
class User {}
''');
  }

  Future<void> test_multiLineBlockIsOneSentence() async {
    await assertNoDiagnostics(r'''
/// A user of the system, holding the identity that every
/// other record in the database ultimately points back
/// to.
class User {}
''');
  }

  Future<void> test_regularCommentIsExemptByDefault() async {
    await assertNoDiagnostics(r'''
// a note to the reader
class User {}
''');
  }

  Future<void> test_ignoreDirectiveIsExempt() async {
    await assertNoDiagnostics(r'''
/// ignore: something
class User {}
''');
  }

  // Edge case: not TODO or FIXME, since the analyzer reports both with a diagnostic of its own
  Future<void> test_coverageToolDirectiveIsExempt() async {
    await assertNoDiagnostics(r'''
/// coverage: ignore-file
class User {}
''');
  }

  Future<void> test_directiveMatchesFirstWordNotLinePrefix() async {
    await assertNoDiagnostics(r'''
/// Never inflated to a full score: real retirements stop mid-set, and
/// that partial set is
/// part of what happened.
class User {}
''');
  }

  Future<void> test_urlIsExempt() async {
    await assertNoDiagnostics(r'''
/// https://dart.dev/effective-dart/documentation
class User {}
''');
  }

  Future<void> test_sentenceMentioningAFileIsStillProse() async {
    await assertNoDiagnostics(r'''
/// A player, never an account: a ghost sits in the table exactly like
/// someone who has claimed their profile (`plan.md` section 3.5).
class User {}
''');
  }

  Future<void> test_codeFenceIsExempt() async {
    await assertNoDiagnostics(r'''
/// Builds a user.
///
/// ```dart
/// final user = User();
/// ```
class User {}
''');
  }

  Future<void> test_leadingIdentifierReferenceIsExempt() async {
    await assertNoDiagnostics(r'''
/// [value] is the identity every record points back to.
class User {}
''');
  }

  Future<void> test_leadingBareIdentifierIsExempt() async {
    await assertNoDiagnostics(r'''
/// dart_frog mounts a dynamic route directory before its static sibling.
class User {}
''');
  }

  Future<void> test_leadingLowercaseWordStillReports() async {
    await assertDiagnostics(
      r'''
/// mounts a dynamic route directory before its static sibling.
class User {}
''',
      [lint(0, 63)],
    );
  }

  Future<void> test_closedTemplateMacroIsExempt() async {
    await assertNoDiagnostics(r'''
/// {@template user}
/// {@endtemplate}
class User {}
''');
  }
}

@reflectiveTest
class FormatCommentRegularCommentsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = FormatComment();
    super.setUp();
    ConfigLoader.clearCache();
    newFile(
      '$testPackageRootPath/${ConfigLoader.fileName}',
      'rules:\n'
          '  format_comment:\n'
          '    check_regular_comments: true\n',
    );
  }

  Future<void> test_regularCommentIsChecked() async {
    await assertDiagnostics(
      r'''
// a note to the reader
class User {}
''',
      [lint(0, 23)],
    );
  }

  Future<void> test_wellFormedRegularComment() async {
    await assertNoDiagnostics(r'''
// A note to the reader.
class User {}
''');
  }
}
