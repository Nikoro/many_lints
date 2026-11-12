import 'package:many_lints/src/rule_config.dart';
import 'package:many_lints/src/rules/format_test_name.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FormatTestNameTest);
    defineReflectiveTests(FormatTestNameUnconfiguredTest);
  });
}

@reflectiveTest
class FormatTestNameTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = FormatTestName();
    super.setUp();
    ConfigLoader.clearCache();
    newFile(
      '$testPackageRootPath/${ConfigLoader.fileName}',
      'rules:\n'
          '  format_test_name:\n'
          "    pattern: 'should .*'\n",
    );
  }

  Future<void> test_nameDoesNotMatchPattern() async {
    await assertDiagnostics(
      r'''
void test(String name, void Function() body) {}

void main() {
  test('works fine', () {});
}
''',
      [lint(70, 12)],
    );
  }

  Future<void> test_nameMatchesPattern() async {
    await assertNoDiagnostics(r'''
void test(String name, void Function() body) {}

void main() {
  test('should work fine', () {});
}
''');
  }

  Future<void> test_groupIsExemptByDefault() async {
    await assertNoDiagnostics(r'''
void group(String name, void Function() body) {}

void main() {
  group('UserRepository', () {});
}
''');
  }

  Future<void> test_nonLiteralInterpolatedNameIsSkipped() async {
    await assertNoDiagnostics(r'''
void test(String name, void Function() body) {}

void main() {
  const subject = 'x';
  test('$subject works', () {});
}
''');
  }
}

@reflectiveTest
class FormatTestNameUnconfiguredTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = FormatTestName();
    super.setUp();
  }

  Future<void> test_silentWithoutAPattern() async {
    await assertNoDiagnostics(r'''
void test(String name, void Function() body) {}

void main() {
  test('works fine', () {});
}
''');
  }
}
