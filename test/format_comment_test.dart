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

  // The block is the unit: a sentence spanning three lines is capitalised on
  // the first and terminated on the last.
  Future<void> test_multiLineBlockIsOneSentence() async {
    await assertNoDiagnostics(r'''
/// A user of the system, holding the identity that every
/// other record in the database ultimately points back
/// to.
class User {}
''');
  }

  // A regular comment is not checked by default.
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

  // `TODO` and `FIXME` are exempt too, but the analyzer reports its own
  // diagnostic for both, which would make this fixture assert the SDK's
  // behaviour rather than this rule's exemption. `coverage:` is checked here
  // because nothing else claims it.
  Future<void> test_toolDirectiveIsExempt() async {
    await assertNoDiagnostics(r'''
/// coverage: ignore-file
class User {}
''');
  }

  // A directive is matched on the first WORD. `startsWith` over the raw line
  // made every directive a prefix of ordinary English: `part` matched "part of
  // what happened.", which silently made the line ABOVE it the block's last
  // prose line and reported it for missing a period.
  Future<void> test_directiveIsNotAPrefixOfEnglish() async {
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

  // Only a line that IS a bare URL is exempt, not a sentence that mentions a
  // file. Exempting the latter dropped it from its block, which then reported
  // the line above it for missing a period.
  Future<void> test_sentenceMentioningAFileIsStillProse() async {
    await assertNoDiagnostics(r'''
/// A player, never an account: a ghost sits in the table exactly like
/// someone who has claimed their profile (`plan.md` section 3.5).
class User {}
''');
  }

  // A fenced code block inside a doc comment is not prose.
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

  // A line opening on an identifier is describing code, and Dart identifiers
  // are conventionally lowercase.
  Future<void> test_leadingIdentifierReferenceIsExempt() async {
    await assertNoDiagnostics(r'''
/// [value] is the identity every record points back to.
class User {}
''');
  }

  // A `{@template}` with no closing tag is the analyzer's complaint, not this
  // rule's; the point of the fixture is that `format_comment` stays silent.
  // Closed, because an unterminated `{@template}` is an analyzer diagnostic in
  // its own right and would drown out what this fixture is for.
  // A bare identifier opening the sentence is the backticked case without the
  // backticks: capitalising `dart_frog` or `runApp` would falsify the name.
  Future<void> test_leadingBareIdentifierIsExempt() async {
    await assertNoDiagnostics(r'''
/// dart_frog mounts a dynamic route directory before its static sibling.
class User {}
''');
  }

  // ...but an ordinary lowercase word still reports, which is the asymmetric
  // half proving the exemption is about identifiers rather than about case.
  Future<void> test_leadingLowercaseWordStillReports() async {
    await assertDiagnostics(
      r'''
/// mounts a dynamic route directory before its static sibling.
class User {}
''',
      [lint(0, 63)],
    );
  }

  Future<void> test_macroIsExempt() async {
    await assertNoDiagnostics(r'''
/// {@template user}
/// {@endtemplate}
class User {}
''');
  }
}

/// The asymmetric positive for `check_regular_comments`: the same comment that
/// is silent by default must report once the option is on.
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
