import 'package:many_lints/src/rules/avoid_too_many_methods.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidTooManyMethodsTest));
}

@reflectiveTest
class AvoidTooManyMethodsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidTooManyMethods();
    super.setUp();
  }

  /// A class declaring [count] trivial methods.
  String _classOf(int count) {
    final methods = List.generate(count, (i) => '  void m$i() {}').join('\n');
    return 'class C {\n$methods\n}\n';
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_overTheDefaultBudget() async {
    await assertDiagnostics(_classOf(21), [lint(6, 1)]);
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_atTheDefaultBudget() async {
    await assertNoDiagnostics(_classOf(20));
  }

  Future<void> test_smallClass() async {
    await assertNoDiagnostics(r'''
class C {
  void a() {}
  void b() {}
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_accessorsAreNotCountedByDefault() async {
    // A data class of 25 getters is the class's surface, not its behaviour.
    final getters = List.generate(25, (i) => '  int get g$i => $i;').join('\n');

    await assertNoDiagnostics('class C {\n$getters\n}\n');
  }

  Future<void> test_constructorsAreNeverCounted() async {
    final constructors = List.generate(25, (i) => '  C.n$i();').join('\n');

    await assertNoDiagnostics('class C {\n$constructors\n}\n');
  }

  Future<void> test_extensionIsAlsoMeasured() async {
    final methods = List.generate(21, (i) => '  void m$i() {}').join('\n');

    await assertDiagnostics('extension E on int {\n$methods\n}\n', [
      lint(10, 1),
    ]);
  }
}
