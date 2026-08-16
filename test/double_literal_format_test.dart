import 'package:many_lints/src/rules/double_literal_format.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(DoubleLiteralFormatTest));
}

@reflectiveTest
class DoubleLiteralFormatTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = DoubleLiteralFormat();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_missingLeadingZero() async {
    await assertDiagnostics(
      r'''
final x = .5;
''',
      [lint(10, 2)],
    );
  }

  Future<void> test_trailingZero() async {
    await assertDiagnostics(
      r'''
final x = 0.50;
''',
      [lint(10, 4)],
    );
  }

  Future<void> test_redundantLeadingZero() async {
    await assertDiagnostics(
      r'''
final x = 00.5;
''',
      [lint(10, 4)],
    );
  }

  Future<void> test_trailingZeroWithExponent() async {
    await assertDiagnostics(
      r'''
final x = 1.50e10;
''',
      [lint(10, 7)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_wellFormedLiteral() async {
    await assertNoDiagnostics(r'''
final x = 0.5;
''');
  }

  Future<void> test_singleZeroFractionIsNotRedundant() async {
    await assertNoDiagnostics(r'''
final x = 1.0;
''');
  }

  Future<void> test_integerLiteralIsIgnored() async {
    await assertNoDiagnostics(r'''
final x = 500;
''');
  }

  Future<void> test_zeroPointZero() async {
    await assertNoDiagnostics(r'''
final x = 0.0;
''');
  }

  // ---- Edge cases ----

  Future<void> test_digitSeparatorsAreLeftToTheOtherRule() async {
    await assertNoDiagnostics(r'''
final x = 1_000.50;
''');
  }

  Future<void> test_exponentWithoutFraction() async {
    await assertNoDiagnostics(r'''
final x = 5e3;
''');
  }
}
