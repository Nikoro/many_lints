import 'package:many_lints/src/rules/avoid_unnecessary_enum_prefix.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidUnnecessaryEnumPrefixTest),
  );
}

@reflectiveTest
class AvoidUnnecessaryEnumPrefixTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryEnumPrefix();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_constantRepeatsEnumName() async {
    await assertDiagnostics(
      r'''
enum Status { statusActive, statusArchived }
''',
      [lint(14, 12), lint(28, 14)],
    );
  }

  Future<void> test_onlySomeConstantsPrefixed() async {
    await assertDiagnostics(
      r'''
enum Status { statusActive, archived }
''',
      [lint(14, 12)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_unprefixedConstants() async {
    await assertNoDiagnostics(r'''
enum Status { active, archived }
''');
  }

  Future<void> test_constantEqualToEnumName() async {
    // `Status.status` is not a prefixed name, it is the whole word.
    await assertNoDiagnostics(r'''
enum Status { status, active }
''');
  }

  Future<void> test_prefixMustEndAtAWordBoundary() async {
    // `statusable` merely starts with the same letters.
    await assertNoDiagnostics(r'''
enum Status { statusable, active }
''');
  }

  // ---- Edge cases ----

  Future<void> test_unrelatedNameSharingLeadingLetters() async {
    await assertNoDiagnostics(r'''
enum Mode { modal, simple }
''');
  }
}
