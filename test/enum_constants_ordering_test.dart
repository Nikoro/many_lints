import 'package:many_lints/src/rule_config.dart';
import 'package:many_lints/src/rules/enum_constants_ordering.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(EnumConstantsOrderingTest));
}

@reflectiveTest
class EnumConstantsOrderingTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = EnumConstantsOrdering();
    super.setUp();

    ConfigLoader.clearCache();
    newFile(
      '$testPackageRootPath/${ConfigLoader.fileName}',
      'rules:\n  enum_constants_ordering:\n    order: alphabetical\n',
    );
  }

  Future<void> test_unorderedConstants() async {
    await assertDiagnostics(
      r'''
enum Fruit { banana, apple, cherry }
''',
      [lint(21, 5)],
    );
  }

  Future<void> test_onlyTheFirstOutOfOrderIsReported() async {
    await assertDiagnostics(
      r'''
enum Fruit { zebra, apple, banana, cherry }
''',
      [lint(20, 5)],
    );
  }

  Future<void> test_orderedConstants() async {
    await assertNoDiagnostics(r'''
enum Fruit { apple, banana, cherry }
''');
  }

  Future<void> test_singleConstant() async {
    await assertNoDiagnostics(r'''
enum Only { one }
''');
  }

  Future<void> test_caseInsensitiveByDefault() async {
    await assertNoDiagnostics(r'''
enum Mixed { apple, Banana, cherry }
''');
  }
}
