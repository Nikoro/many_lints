import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_duplicate_cascades.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidDuplicateCascadesTest),
  );
}

@reflectiveTest
class AvoidDuplicateCascadesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidDuplicateCascades();
    super.setUp();
  }

  // --- Positive cases: should trigger lint ---

  Future<void> test_duplicatePropertyAssignment() async {
    await assertDiagnostics(
      r'''
class Foo {
  String field = '';
}
void f() {
  Foo()
    ..field = '1'
    ..field = '1';
}
''',
      [lint(76, 13)],
    );
  }

  Future<void> test_duplicateMethodCall() async {
    await assertDiagnostics(
      r'''
class Foo {
  void bar() {}
}
void f() {
  Foo()
    ..bar()
    ..bar();
}
''',
      [lint(65, 7)],
    );
  }

  Future<void> test_duplicateMethodCallWithSameArgs() async {
    await assertDiagnostics(
      r'''
class Foo {
  void bar(int x) {}
}
void f() {
  Foo()
    ..bar(1)
    ..bar(1);
}
''',
      [lint(71, 8)],
    );
  }

  Future<void> test_duplicateIndexAssignment() async {
    await assertDiagnostics(
      r'''
void f() {
  [1, 2, 3]
    ..[1] = 2
    ..[1] = 2;
}
''',
      [lint(41, 9)],
    );
  }

  Future<void> test_tripleDuplicatePropertyAssignment() async {
    await assertDiagnostics(
      r'''
class Foo {
  String field = '';
}
void f() {
  Foo()
    ..field = '1'
    ..field = '1'
    ..field = '1';
}
''',
      [lint(76, 13), lint(94, 13)],
    );
  }

  // --- Negative cases: should NOT trigger lint ---

  Future<void> test_differentPropertyAssignments() async {
    await assertNoDiagnostics(r'''
class Foo {
  String field1 = '';
  String field2 = '';
}
void f() {
  Foo()
    ..field1 = '1'
    ..field2 = '2';
}
''');
  }

  Future<void> test_samePropertyDifferentValues() async {
    await assertNoDiagnostics(r'''
class Foo {
  String field = '';
}
void f() {
  Foo()
    ..field = '1'
    ..field = '2';
}
''');
  }

  Future<void> test_differentMethodCalls() async {
    await assertNoDiagnostics(r'''
class Foo {
  void bar() {}
  void baz() {}
}
void f() {
  Foo()
    ..bar()
    ..baz();
}
''');
  }

  Future<void> test_sameMethodDifferentArgs() async {
    await assertNoDiagnostics(r'''
class Foo {
  void bar(int x) {}
}
void f() {
  Foo()
    ..bar(1)
    ..bar(2);
}
''');
  }

  Future<void> test_differentIndexAssignments() async {
    await assertNoDiagnostics(r'''
void f() {
  [1, 2, 3]
    ..[0] = 10
    ..[1] = 20;
}
''');
  }

  Future<void> test_singleCascade() async {
    await assertNoDiagnostics(r'''
class Foo {
  String field = '';
}
void f() {
  Foo()..field = '1';
}
''');
  }
}
