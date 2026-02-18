import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_class_destructuring.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferClassDestructuringTest),
  );
}

@reflectiveTest
class PreferClassDestructuringTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferClassDestructuring();
    super.setUp();
  }

  Future<void> test_threeDistinctProperties_triggers() async {
    await assertDiagnostics(
      r'''
class Foo {
  int get x => 1;
  int get y => 2;
  int get z => 3;
}

void f(Foo foo) {
  print(foo.x);
  print(foo.y);
  print(foo.z);
}
''',
      [lint(95, 5)],
    );
  }

  Future<void> test_twoProperties_noLint() async {
    await assertNoDiagnostics(r'''
class Foo {
  int get x => 1;
  int get y => 2;
}

void f(Foo foo) {
  print(foo.x);
  print(foo.y);
}
''');
  }

  Future<void> test_samePropertyAccessedMultipleTimes_noLint() async {
    await assertNoDiagnostics(r'''
class Foo {
  int get x => 1;
}

void f(Foo foo) {
  print(foo.x);
  print(foo.x);
  print(foo.x);
}
''');
  }

  Future<void> test_localVariable_triggers() async {
    await assertDiagnostics(
      r'''
class Bar {
  String get a => 'a';
  String get b => 'b';
  String get c => 'c';
}

void f() {
  final bar = Bar();
  print(bar.a);
  print(bar.b);
  print(bar.c);
}
''',
      [lint(124, 5)],
    );
  }

  Future<void> test_methodCallOnVariable_notCounted() async {
    await assertNoDiagnostics(r'''
class Foo {
  int get x => 1;
  int get y => 2;
  void doSomething() {}
}

void f(Foo foo) {
  print(foo.x);
  print(foo.y);
  foo.doSomething();
}
''');
  }

  Future<void> test_differentVariables_noLint() async {
    await assertNoDiagnostics(r'''
class Foo {
  int get x => 1;
  int get y => 2;
  int get z => 3;
}

void f(Foo a, Foo b) {
  print(a.x);
  print(b.y);
  print(a.z);
}
''');
  }

  Future<void> test_assignmentTarget_notCounted() async {
    await assertNoDiagnostics(r'''
class Foo {
  int x = 1;
  int y = 2;
  int z = 3;
}

void f(Foo foo) {
  foo.x = 10;
  foo.y = 20;
  foo.z = 30;
}
''');
  }

  Future<void> test_nestedFunction_separateScope() async {
    await assertNoDiagnostics(r'''
class Foo {
  int get x => 1;
  int get y => 2;
  int get z => 3;
}

void f(Foo foo) {
  print(foo.x);
  print(foo.y);
  () {
    print(foo.z);
  };
}
''');
  }

  Future<void> test_nonInterfaceType_noLint() async {
    await assertNoDiagnostics(r'''
void f(dynamic foo) {
  print(foo.x);
  print(foo.y);
  print(foo.z);
}
''');
  }

  Future<void> test_fourProperties_reportsCountInMessage() async {
    await assertDiagnostics(
      r'''
class Foo {
  int get a => 1;
  int get b => 2;
  int get c => 3;
  int get d => 4;
}

void f(Foo foo) {
  print(foo.a);
  print(foo.b);
  print(foo.c);
  print(foo.d);
}
''',
      [lint(113, 5)],
    );
  }

  Future<void> test_fieldAccessNotTopLevel_noLint() async {
    await assertNoDiagnostics(r'''
class Foo {
  int get x => 1;
  int get y => 2;
  int get z => 3;
}

class Bar {
  final Foo foo = Foo();

  void f() {
    print(foo.x);
    print(foo.y);
    print(foo.z);
  }
}
''');
  }

  Future<void> test_mixedReadAndMethodCall_thresholdMet() async {
    await assertDiagnostics(
      r'''
class Foo {
  int get x => 1;
  int get y => 2;
  int get z => 3;
  void doSomething() {}
}

void f(Foo foo) {
  foo.doSomething();
  print(foo.x);
  print(foo.y);
  print(foo.z);
}
''',
      [lint(140, 5)],
    );
  }
}
