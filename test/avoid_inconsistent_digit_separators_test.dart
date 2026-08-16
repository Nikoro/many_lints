import 'package:many_lints/src/rules/avoid_inconsistent_digit_separators.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidInconsistentDigitSeparatorsTest),
  );
}

@reflectiveTest
class AvoidInconsistentDigitSeparatorsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidInconsistentDigitSeparators();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_irregularGroups() async {
    await assertDiagnostics(
      r'''
final x = 10_00_000;
''',
      [lint(10, 9)],
    );
  }

  Future<void> test_leadingGroupLongerThanTheRest() async {
    await assertDiagnostics(
      r'''
final x = 1000_000;
''',
      [lint(10, 8)],
    );
  }

  Future<void> test_hexGroupedByThrees() async {
    await assertDiagnostics(
      r'''
final x = 0xFF_FFF_FFF;
''',
      [lint(10, 12)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_regularThousands() async {
    await assertNoDiagnostics(r'''
final x = 1_000_000;
''');
  }

  Future<void> test_shortLeadingGroupIsFine() async {
    await assertNoDiagnostics(r'''
final x = 12_345_678;
''');
  }

  Future<void> test_noSeparatorsAtAll() async {
    await assertNoDiagnostics(r'''
final x = 1000000;
''');
  }

  Future<void> test_hexGroupedByFours() async {
    await assertNoDiagnostics(r'''
final x = 0xFFFF_FFFF;
''');
  }

  // ---- Edge cases ----

  Future<void> test_doubleLiteralWithGroupedWholePart() async {
    await assertNoDiagnostics(r'''
final x = 1_000.5;
''');
  }

  Future<void> test_singleGroupIsAlwaysConsistent() async {
    await assertNoDiagnostics(r'''
final x = 1_000;
''');
  }
}
