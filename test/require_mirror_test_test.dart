import 'package:many_lints/src/rules/require_mirror_test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RequireMirrorTestTest);
    defineReflectiveTests(RequireMirrorTestNestedTest);
    defineReflectiveTests(RequireMirrorTestOutsideLibTest);
  });
}

@reflectiveTest
class RequireMirrorTestTest extends ManyLintsRuleTest {
  @override
  String get testFileName => 'parser.dart';

  @override
  void setUp() {
    rule = RequireMirrorTest();
    super.setUp();
  }

  Future<void> test_missingTestFileIsReported() async {
    await assertDiagnostics(
      r'''
class Parser {}
''',
      [lint(0, 5)],
    );
  }

  Future<void> test_mirroredTestFileSatisfiesTheRule() async {
    newFile('$testPackageRootPath/test/parser_test.dart', 'void main() {}');

    await assertNoDiagnostics(r'''
class Parser {}
''');
  }

  /// A test of the right name elsewhere in the tree still counts, so
  /// reorganising the test folder does not turn the rule into noise.
  Future<void> test_fallbackAnywhereFindsAMovedTest() async {
    newFile(
      '$testPackageRootPath/test/unit/parsing/parser_test.dart',
      'void main() {}',
    );

    await assertNoDiagnostics(r'''
class Parser {}
''');
  }

  Future<void> test_barrelFileIsSkipped() async {
    await assertNoDiagnostics(r'''
export 'dart:async';
''');
  }

  Future<void> test_fileWithNoPublicElementIsSkipped() async {
    await assertNoDiagnostics(r'''
class _Parser {}

void _helper() {}
''');
  }

  Future<void> test_publicTopLevelVariableNeedsATest() async {
    await assertDiagnostics(
      r'''
const parserVersion = 3;
''',
      [lint(0, 5)],
    );
  }

  /// A file that both exports and declares is not a barrel: it has code of
  /// its own that a test could reach.
  Future<void> test_exportPlusDeclarationIsNotABarrel() async {
    await assertDiagnostics(
      r'''
export 'dart:async';

class Parser {}
''',
      [lint(0, 6)],
    );
  }
}

/// A nested library mirrors into the matching nested test path.
@reflectiveTest
class RequireMirrorTestNestedTest extends ManyLintsRuleTest {
  @override
  String get testFileName => 'src/core/version.dart';

  @override
  void setUp() {
    rule = RequireMirrorTest();
    super.setUp();
  }

  Future<void> test_nestedMirrorPathIsExpected() async {
    await assertDiagnostics(
      r'''
class Version {}
''',
      [lint(0, 5)],
    );
  }

  Future<void> test_nestedMirrorPathSatisfiesTheRule() async {
    newFile(
      '$testPackageRootPath/test/src/core/version_test.dart',
      'void main() {}',
    );

    await assertNoDiagnostics(r'''
class Version {}
''');
  }
}

/// The rule is scoped to `lib/`; a test file has no test of its own.
@reflectiveTest
class RequireMirrorTestOutsideLibTest extends ManyLintsRuleTest {
  @override
  String get testPackageLibPath => '$testPackageRootPath/test';

  @override
  String get testFileName => 'parser_test.dart';

  @override
  void setUp() {
    rule = RequireMirrorTest();
    super.setUp();
  }

  Future<void> test_fileOutsideLibIsSilent() async {
    await assertNoDiagnostics(r'''
class ParserTest {}
''');
  }
}
