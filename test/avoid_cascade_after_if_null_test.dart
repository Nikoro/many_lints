import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_cascade_after_if_null.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidCascadeAfterIfNullTest),
  );
}

@reflectiveTest
class AvoidCascadeAfterIfNullTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidCascadeAfterIfNull();
    super.setUp();
  }

  Future<void> test_cascadeAfterIfNull_method() async {
    await assertDiagnostics(
      r'''
class Foo { void bar() {} }
void f(Foo? x) {
  x ?? Foo()..bar();
}
''',
      [lint(47, 17)],
    );
  }

  Future<void> test_cascadeAfterIfNull_property() async {
    await assertDiagnostics(
      r'''
class Foo { int value = 0; }
void f(Foo? x) {
  x ?? Foo()..value = 1;
}
''',
      [lint(48, 21)],
    );
  }

  Future<void> test_cascadeAfterIfNull_multipleSections() async {
    await assertDiagnostics(
      r'''
class Foo {
  void bar() {}
  int value = 0;
}
void f(Foo? x) {
  x ?? Foo()..bar()..value = 1;
}
''',
      [lint(66, 28)],
    );
  }

  Future<void> test_noCascade_parenthesizedLeft() async {
    await assertNoDiagnostics(r'''
class Foo { void bar() {} }
void f(Foo? x) {
  (x ?? Foo())..bar();
}
''');
  }

  Future<void> test_noCascade_parenthesizedRight() async {
    await assertNoDiagnostics(r'''
class Foo { void bar() {} }
void f(Foo? x) {
  x ?? (Foo()..bar());
}
''');
  }

  Future<void> test_noCascade_withoutIfNull() async {
    await assertNoDiagnostics(r'''
class Foo { void bar() {} }
void f() {
  Foo()..bar();
}
''');
  }

  Future<void> test_noCascade_otherBinaryOperator() async {
    await assertNoDiagnostics(r'''
void f() {
  final list = [1, 2, 3];
  list..add(4);
}
''');
  }
}
