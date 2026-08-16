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

    // The rule is silent without an `order:`, so every test needs one. This
    // replaces the base class's plain `enabled: true`.
    ConfigLoader.clearCache();
    newFile(
      '$testPackageRootPath/${ConfigLoader.fileName}',
      'rules:\n  enum_constants_ordering:\n    order: alphabetical\n',
    );
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_unorderedConstants() async {
    await assertDiagnostics(
      r'''
enum Fruit { banana, apple, cherry }
''',
      [lint(21, 5)],
    );
  }

  Future<void> test_onlyTheFirstOutOfOrderIsReported() async {
    // One misplaced name makes every later name look wrong too; reporting all
    // of them would turn one edit into a wall of diagnostics.
    await assertDiagnostics(
      r'''
enum Fruit { zebra, apple, banana, cherry }
''',
      [lint(20, 5)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

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

  // ---- Edge cases ----

  Future<void> test_caseInsensitiveByDefault() async {
    // Case-sensitive sorting would put every capitalised name in a block
    // before the lowercase ones, which reads as two lists rather than one.
    await assertNoDiagnostics(r'''
enum Mixed { apple, Banana, cherry }
''');
  }
}
