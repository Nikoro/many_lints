import 'package:many_lints/src/rules/avoid_nested_conditional_expressions.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidNestedConditionalExpressionsTest),
  );
}

@reflectiveTest
class AvoidNestedConditionalExpressionsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidNestedConditionalExpressions();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_nestedInElseBranch() async {
    await assertDiagnostics(
      r'''
String f(int x) => x > 0 ? 'pos' : (x < 0 ? 'neg' : 'zero');
''',
      [lint(19, 40)],
    );
  }

  Future<void> test_nestedInThenBranch() async {
    await assertDiagnostics(
      r'''
String f(int x) => x > 0 ? (x > 10 ? 'big' : 'small') : 'neg';
''',
      [lint(19, 42)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_singleConditional() async {
    await assertNoDiagnostics(r'''
String f(int x) => x > 0 ? 'pos' : 'neg';
''');
  }

  Future<void> test_twoSeparateConditionals() async {
    await assertNoDiagnostics(r'''
String f(int x, int y) {
  final a = x > 0 ? 'pos' : 'neg';
  final b = y > 0 ? 'pos' : 'neg';
  return a + b;
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_reportedOnceAtTheOutermost() async {
    // Three levels deep still produces a single diagnostic.
    await assertDiagnostics(
      r'''
String f(int x) =>
    x > 0 ? 'a' : (x < 0 ? 'b' : (x == 0 ? 'c' : 'd'));
''',
      [lint(23, 50)],
    );
  }
}
