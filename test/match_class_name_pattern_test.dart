import 'package:many_lints/src/rule_config.dart';
import 'package:many_lints/src/rules/match_class_name_pattern.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(MatchClassNamePatternTest));
}

@reflectiveTest
class MatchClassNamePatternTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = MatchClassNamePattern();
    super.setUp();
    ConfigLoader.clearCache();
    newFile(
      '$testPackageRootPath/${ConfigLoader.fileName}',
      'rules:\n'
          '  match_class_name_pattern:\n'
          "    pattern: '[A-Z][A-Za-z0-9]*Page'\n",
    );
  }

  Future<void> test_nameDoesNotMatch() async {
    await assertDiagnostics(
      r'''
class Home {}
''',
      [lint(6, 4)],
    );
  }

  Future<void> test_nameMatches() async {
    await assertNoDiagnostics(r'''
class HomePage {}
''');
  }

  // The pattern must match the WHOLE name, so a prefix match is not enough.
  Future<void> test_patternIsAnchored() async {
    await assertDiagnostics(
      r'''
class HomePageExtra {}
''',
      [lint(6, 13)],
    );
  }
}
