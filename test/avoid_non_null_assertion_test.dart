import 'package:many_lints/src/rules/avoid_non_null_assertion.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidNonNullAssertionTest));
}

@reflectiveTest
class AvoidNonNullAssertionTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidNonNullAssertion();
    super.setUp();
  }

  Future<void> test_bangOnPropertyAccess() async {
    await assertDiagnostics(
      r'''
class C {
  String? field;
}

void f(C c) {
  c.field!.length;
}
''',
      [lint(46, 8)],
    );
  }

  Future<void> test_bangOnMethodInvocationTarget() async {
    await assertDiagnostics(
      r'''
class C {
  C? object;
  void method() {}
}

void f(C c) {
  c.object!.method();
}
''',
      [lint(61, 9)],
    );
  }

  Future<void> test_chainedBangsReportedSeparately() async {
    await assertDiagnostics(
      r'''
class C {
  C? object;
  String? field;
}

void f(C c) {
  c.object!.field!.length;
}
''',
      [lint(59, 16), lint(59, 9)],
    );
  }

  Future<void> test_bangOnLocalVariable() async {
    await assertDiagnostics(
      r'''
void f(int? n) {
  print(n!);
}
''',
      [lint(25, 2)],
    );
  }

  Future<void> test_mapIndexIsExempt() async {
    await assertNoDiagnostics(r'''
void f(Map<String, String> m) {
  m['key']!.length;
}
''');
  }

  Future<void> test_mapSubtypeIndexIsExempt() async {
    await assertNoDiagnostics(r'''
import 'dart:collection';

void f(HashMap<String, String> m) {
  m['key']!.length;
}
''');
  }

  Future<void> test_listIndexIsNotExempt() async {
    await assertDiagnostics(
      r'''
void f(List<String?> list) {
  list[0]!.length;
}
''',
      [lint(31, 8)],
    );
  }

  Future<void> test_nullAwareAccessIsFine() async {
    await assertNoDiagnostics(r'''
class C {
  String? field;
}

void f(C c) {
  c.field?.length;
}
''');
  }

  Future<void> test_nullCheckIsFine() async {
    await assertNoDiagnostics(r'''
void f(String? value) {
  if (value != null) {
    print(value.length);
  }
}
''');
  }

  Future<void> test_notEqualsOperatorIsNotABang() async {
    await assertNoDiagnostics(r'''
void f(int a, int b) {
  if (a != b) {
    print(a);
  }
}
''');
  }

  Future<void> test_incrementIsNotABang() async {
    await assertNoDiagnostics(r'''
void f() {
  var i = 0;
  i++;
  i--;
}
''');
  }

  Future<void> test_negationIsNotABang() async {
    await assertNoDiagnostics(r'''
void f(bool value) {
  if (!value) {
    print(value);
  }
}
''');
  }

  Future<void> test_nullAssertPatternIsNotReported() async {
    // A `!` in a pattern is a `NullAssertPattern`, not a `PostfixExpression`.
    await assertNoDiagnostics(r'''
void f((int?,) record) {
  var (x!,) = record;
  print(x);
}
''');
  }

  /// The default reports a bang even where an enclosing `if` checked the field:
  /// promotion does not apply to fields, so the bang is load-bearing.
  Future<void> test_checkedFieldReportedByDefault() async {
    await assertDiagnostics(
      r'''
class C {
  String? field;

  void f() {
    if (field != null) {
      print(field!.length);
    }
  }
}
''',
      [lint(78, 6)],
    );
  }
}
