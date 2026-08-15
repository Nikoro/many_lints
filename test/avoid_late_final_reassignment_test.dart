import 'package:many_lints/src/rules/avoid_late_final_reassignment.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidLateFinalReassignmentTest),
  );
}

@reflectiveTest
class AvoidLateFinalReassignmentTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidLateFinalReassignment();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_assignedTwiceInOneBlock() async {
    await assertDiagnostics(
      r'''
class A {
  late final int value;

  void setUp() {
    value = 1;
    value = 2;
  }
}
''',
      [lint(71, 9)],
    );
  }

  Future<void> test_assignedThroughThis() async {
    await assertDiagnostics(
      r'''
class A {
  late final int value;

  void setUp() {
    this.value = 1;
    this.value = 2;
  }
}
''',
      [lint(76, 14)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_assignedOnce() async {
    await assertNoDiagnostics(r'''
class A {
  late final int value;

  void setUp() {
    value = 1;
  }
}
''');
  }

  Future<void> test_assignedInOppositeBranches() async {
    // This is exactly how a `late final` is meant to be initialised.
    await assertNoDiagnostics(r'''
class A {
  late final int value;

  void setUp(bool flag) {
    if (flag) {
      value = 1;
    } else {
      value = 2;
    }
  }
}
''');
  }

  Future<void> test_lateWithoutFinalMayChange() async {
    await assertNoDiagnostics(r'''
class A {
  late int value;

  void setUp() {
    value = 1;
    value = 2;
  }
}
''');
  }

  Future<void> test_plainFieldMayChange() async {
    await assertNoDiagnostics(r'''
class A {
  int value = 0;

  void setUp() {
    value = 1;
    value = 2;
  }
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_differentLateFinalFields() async {
    await assertNoDiagnostics(r'''
class A {
  late final int first;
  late final int second;

  void setUp() {
    first = 1;
    second = 2;
  }
}
''');
  }
}
