import 'package:many_lints/src/rules/avoid_self_compare.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidSelfCompareTest));
}

@reflectiveTest
class AvoidSelfCompareTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidSelfCompare();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_compareToSelf() async {
    await assertDiagnostics(
      r'''
int f(String s) => s.compareTo(s);
''',
      [lint(19, 14)],
    );
  }

  Future<void> test_compareToSelfOnField() async {
    await assertDiagnostics(
      r'''
class A {
  final String name = '';
  int f() => name.compareTo(name);
}
''',
      [lint(49, 20)],
    );
  }

  Future<void> test_compareToSelfOnPropertyChain() async {
    await assertDiagnostics(
      r'''
class Inner {
  final String value = '';
}

class A {
  final Inner inner = Inner();
  int f() => inner.value.compareTo(inner.value);
}
''',
      [lint(98, 34)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_compareToDifferentValue() async {
    await assertNoDiagnostics(r'''
int f(String a, String b) => a.compareTo(b);
''');
  }

  Future<void> test_compareToDifferentFields() async {
    await assertNoDiagnostics(r'''
class A {
  final String first = '';
  final String second = '';
  int f() => first.compareTo(second);
}
''');
  }

  Future<void> test_equalOperatorIsAnotherRule() async {
    // `a == a` belongs to avoid_equal_expressions; reporting it here too
    // would put two diagnostics on one line.
    await assertNoDiagnostics(r'''
bool f(int a) => a == a;
''');
  }

  // ---- Edge cases ----

  Future<void> test_methodCallOperandsMayDiffer() async {
    // `next()` is called twice and can return different values.
    await assertNoDiagnostics(r'''
int g(String Function() next) => next().compareTo(next());
''');
  }

  Future<void> test_getterMayReportAMovingValue() async {
    // A getter runs a body, so two reads need not agree. Only a field-backed
    // read is treated as stable.
    await assertNoDiagnostics(r'''
class Cursor {
  int _position = 0;
  String get current => '$_position';
  int f() => current.compareTo(current);
}
''');
  }

  Future<void> test_compareToWithNoTarget() async {
    await assertNoDiagnostics(r'''
class A implements Comparable<A> {
  @override
  int compareTo(A other) => 0;

  int f(A other) => compareTo(other);
}
''');
  }
}
