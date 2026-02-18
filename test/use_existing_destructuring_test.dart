import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/use_existing_destructuring.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(UseExistingDestructuringTest),
  );
}

@reflectiveTest
class UseExistingDestructuringTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = UseExistingDestructuring();
    super.setUp();
  }

  // --- Positive cases (should trigger lint) ---

  Future<void>
  test_objectPattern_propertyAccessNotDestructured_triggers() async {
    await assertDiagnostics(
      r'''
class Foo {
  final int value;
  final int another;
  Foo(this.value, this.another);
}

void f(Foo variable) {
  final Foo(:value) = variable;
  print(variable.another);
}
''',
      [lint(151, 16)],
    );
  }

  Future<void> test_objectPattern_multipleUndeclaredAccesses_triggers() async {
    await assertDiagnostics(
      r'''
class Foo {
  final int x;
  final int y;
  final int z;
  Foo(this.x, this.y, this.z);
}

void f(Foo obj) {
  final Foo(:x) = obj;
  print(obj.y);
  print(obj.z);
}
''',
      [lint(140, 5), lint(156, 5)],
    );
  }

  Future<void> test_objectPattern_threeFieldsOneDestructured_triggers() async {
    await assertDiagnostics(
      r'''
class Bar {
  final int a;
  final int b;
  final int c;
  Bar(this.a, this.b, this.c);
}

void f(Bar bar) {
  final Bar(:a) = bar;
  print(bar.b);
  print(bar.c);
}
''',
      [lint(140, 5), lint(156, 5)],
    );
  }

  Future<void> test_prefixedIdentifier_triggers() async {
    await assertDiagnostics(
      r'''
class Foo {
  final int value;
  final String name;
  Foo(this.value, this.name);
}

void f(Foo input) {
  final Foo(:value) = input;
  print(input.name);
}
''',
      [lint(142, 10)],
    );
  }

  Future<void> test_propertyAccessInExpression_triggers() async {
    await assertDiagnostics(
      r'''
class Foo {
  final int value;
  final int other;
  Foo(this.value, this.other);
}

void f(Foo obj) {
  final Foo(:value) = obj;
  final sum = value + obj.other;
}
''',
      [lint(151, 9)],
    );
  }

  // --- Negative cases (should NOT trigger lint) ---

  Future<void> test_alreadyDestructured_noLint() async {
    await assertNoDiagnostics(r'''
class Foo {
  final int value;
  final int another;
  Foo(this.value, this.another);
}

void f(Foo variable) {
  final Foo(:value, :another) = variable;
  print(another);
}
''');
  }

  Future<void> test_noDestructuring_noLint() async {
    await assertNoDiagnostics(r'''
class Foo {
  final int value;
  Foo(this.value);
}

void f(Foo variable) {
  print(variable.value);
}
''');
  }

  Future<void> test_differentVariable_noLint() async {
    await assertNoDiagnostics(r'''
class Foo {
  final int value;
  final int another;
  Foo(this.value, this.another);
}

void f(Foo a, Foo b) {
  final Foo(:value) = a;
  print(b.another);
}
''');
  }

  Future<void> test_accessBeforeDestructuring_noLint() async {
    await assertNoDiagnostics(r'''
class Foo {
  final int value;
  final int another;
  Foo(this.value, this.another);
}

void f(Foo variable) {
  print(variable.another);
  final Foo(:value) = variable;
  print(value);
}
''');
  }

  Future<void> test_nestedFunction_noLint() async {
    await assertNoDiagnostics(r'''
class Foo {
  final int value;
  final int another;
  Foo(this.value, this.another);
}

void f(Foo variable) {
  final Foo(:value) = variable;
  void inner() {
    print(variable.another);
  }
  inner();
}
''');
  }

  Future<void> test_methodCall_noLint() async {
    await assertNoDiagnostics(r'''
class Foo {
  final int value;
  Foo(this.value);
  String describe() => 'Foo($value)';
}

void f(Foo variable) {
  final Foo(:value) = variable;
  print(variable.describe());
}
''');
  }

  Future<void> test_assignmentTarget_noLint() async {
    await assertNoDiagnostics(r'''
class Foo {
  int value;
  int another;
  Foo(this.value, this.another);
}

void f(Foo variable) {
  final Foo(:value) = variable;
  variable.another = 42;
}
''');
  }

  Future<void> test_nonLocalVariable_noLint() async {
    await assertNoDiagnostics(r'''
class Foo {
  final int value;
  final int another;
  Foo(this.value, this.another);
}

final global = Foo(1, 2);

void f() {
  final Foo(:value) = global;
  print(global.another);
}
''');
  }
}
