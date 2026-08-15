import 'package:many_lints/src/rules/avoid_unnecessary_extends.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidUnnecessaryExtendsTest),
  );
}

@reflectiveTest
class AvoidUnnecessaryExtendsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryExtends();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_extendsObject() async {
    await assertDiagnostics(
      r'''
class A extends Object {}
''',
      [lint(8, 14)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_noExtendsClause() async {
    await assertNoDiagnostics(r'''
class A {}
''');
  }

  Future<void> test_extendsRealSuperclass() async {
    await assertNoDiagnostics(r'''
class Base {}
class A extends Base {}
''');
  }

  // ---- Edge cases ----

  Future<void> test_userDeclaredObjectIsMeaningful() async {
    // A local `Object` shadows dart:core's, so extending it is a real choice.
    await assertNoDiagnostics(r'''
class Object {}
class A extends Object {}
''');
  }
}
