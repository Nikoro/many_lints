import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_unnecessary_overrides.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidUnnecessaryOverridesTest),
  );
}

@reflectiveTest
class AvoidUnnecessaryOverridesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryOverrides();
    super.setUp();
  }

  // ── Methods ──────────────────────────────────────────────────────────

  Future<void> test_methodOnlySuperCallNoArgs_block() async {
    await assertDiagnostics(
      r'''
class Base {
  void foo() {}
}

class Child extends Base {
  @override
  void foo() {
    super.foo();
  }
}
''',
      [lint(61, 45)],
    );
  }

  Future<void> test_methodOnlySuperCallNoArgs_expression() async {
    await assertDiagnostics(
      r'''
class Base {
  void foo() {}
}

class Child extends Base {
  @override
  void foo() => super.foo();
}
''',
      [lint(61, 38)],
    );
  }

  Future<void> test_methodOnlySuperCallWithPassThroughArgs() async {
    await assertDiagnostics(
      r'''
class Base {
  void foo(int x, String y) {}
}

class Child extends Base {
  @override
  void foo(int x, String y) {
    super.foo(x, y);
  }
}
''',
      [lint(76, 64)],
    );
  }

  Future<void> test_methodOnlySuperCallWithNamedArgs() async {
    await assertDiagnostics(
      r'''
class Base {
  void foo({required int x, required String y}) {}
}

class Child extends Base {
  @override
  void foo({required int x, required String y}) {
    super.foo(x: x, y: y);
  }
}
''',
      [lint(96, 90)],
    );
  }

  Future<void> test_methodOnlySuperCallWithReturnValue_expression() async {
    await assertDiagnostics(
      r'''
class Base {
  int foo(int x) => x;
}

class Child extends Base {
  @override
  int foo(int x) => super.foo(x);
}
''',
      [lint(68, 43)],
    );
  }

  Future<void> test_methodOnlySuperCallWithReturnValue_block() async {
    await assertDiagnostics(
      r'''
class Base {
  int foo(int x) => x;
}

class Child extends Base {
  @override
  int foo(int x) {
    return super.foo(x);
  }
}
''',
      [lint(68, 57)],
    );
  }

  Future<void> test_methodWithAdditionalStatements() async {
    await assertNoDiagnostics(r'''
class Base {
  void foo() {}
}

class Child extends Base {
  @override
  void foo() {
    print('extra');
    super.foo();
  }
}
''');
  }

  Future<void> test_methodWithDifferentArgs() async {
    await assertNoDiagnostics(r'''
class Base {
  void foo(int x) {}
}

class Child extends Base {
  @override
  void foo(int x) {
    super.foo(x + 1);
  }
}
''');
  }

  Future<void> test_methodWithoutOverrideAnnotation() async {
    await assertNoDiagnostics(r'''
class Base {
  void foo() {}
}

class Child extends Base {
  void foo() {
    super.foo();
  }
}
''');
  }

  Future<void> test_methodCallsDifferentSuperMethod() async {
    await assertNoDiagnostics(r'''
class Base {
  void foo() {}
  void bar() {}
}

class Child extends Base {
  @override
  void foo() {
    super.bar();
  }
}
''');
  }

  // ── Getters ──────────────────────────────────────────────────────────

  Future<void> test_getterOnlyReturnsSuperGetter_expression() async {
    await assertDiagnostics(
      r'''
class Base {
  int get value => 42;
}

class Child extends Base {
  @override
  int get value => super.value;
}
''',
      [lint(68, 41)],
    );
  }

  Future<void> test_getterOnlyReturnsSuperGetter_block() async {
    await assertDiagnostics(
      r'''
class Base {
  int get value => 42;
}

class Child extends Base {
  @override
  int get value {
    return super.value;
  }
}
''',
      [lint(68, 55)],
    );
  }

  Future<void> test_getterWithAdditionalLogic() async {
    await assertNoDiagnostics(r'''
class Base {
  int get value => 42;
}

class Child extends Base {
  @override
  int get value {
    print('accessing value');
    return super.value;
  }
}
''');
  }

  Future<void> test_getterReturnsDifferentExpression() async {
    await assertNoDiagnostics(r'''
class Base {
  int get value => 42;
}

class Child extends Base {
  @override
  int get value => 99;
}
''');
  }

  // ── Setters ──────────────────────────────────────────────────────────

  Future<void> test_setterOnlyDelegatesToSuper_expression() async {
    await assertDiagnostics(
      r'''
class Base {
  set value(int v) {}
}

class Child extends Base {
  @override
  set value(int v) => super.value = v;
}
''',
      [lint(67, 48)],
    );
  }

  Future<void> test_setterOnlyDelegatesToSuper_block() async {
    await assertDiagnostics(
      r'''
class Base {
  set value(int v) {}
}

class Child extends Base {
  @override
  set value(int v) {
    super.value = v;
  }
}
''',
      [lint(67, 55)],
    );
  }

  Future<void> test_setterWithAdditionalLogic() async {
    await assertNoDiagnostics(r'''
class Base {
  set value(int v) {}
}

class Child extends Base {
  @override
  set value(int v) {
    print('setting $v');
    super.value = v;
  }
}
''');
  }

  Future<void> test_setterAssignsDifferentValue() async {
    await assertNoDiagnostics(r'''
class Base {
  set value(int v) {}
}

class Child extends Base {
  @override
  set value(int v) {
    super.value = v + 1;
  }
}
''');
  }

  // ── Abstract redeclarations ──────────────────────────────────────────

  Future<void> test_abstractMethodRedeclaration() async {
    await assertDiagnostics(
      r'''
abstract class Base {
  void foo();
}

abstract class Child extends Base {
  @override
  void foo();
}
''',
      [lint(77, 23)],
    );
  }

  Future<void> test_abstractGetterRedeclaration() async {
    await assertDiagnostics(
      r'''
abstract class Base {
  int get value;
}

abstract class Child extends Base {
  @override
  int get value;
}
''',
      [lint(80, 26)],
    );
  }

  Future<void> test_abstractSetterRedeclaration() async {
    await assertDiagnostics(
      r'''
abstract class Base {
  set value(int v);
}

abstract class Child extends Base {
  @override
  set value(int v);
}
''',
      [lint(83, 29)],
    );
  }

  // ── Mixin ────────────────────────────────────────────────────────────

  Future<void> test_mixinUnnecessaryOverride() async {
    await assertDiagnostics(
      r'''
class Base {
  void foo() {}
}

mixin MyMixin on Base {
  @override
  void foo() => super.foo();
}
''',
      [lint(58, 38)],
    );
  }

  // ── Edge cases ───────────────────────────────────────────────────────

  Future<void> test_emptyMethodBody() async {
    await assertNoDiagnostics(r'''
class Base {
  void foo() {}
}

class Child extends Base {
  @override
  void foo() {}
}
''');
  }

  Future<void> test_operatorOverride() async {
    await assertDiagnostics(
      r'''
class Base {
  bool operator ==(Object other) => identical(this, other);
}

class Child extends Base {
  @override
  bool operator ==(Object other) => super == other;
}
''',
      [lint(105, 61)],
    );
  }

  Future<void> test_multipleUnnecessaryOverrides() async {
    await assertDiagnostics(
      r'''
class Base {
  void foo() {}
  int get value => 0;
}

class Child extends Base {
  @override
  void foo() => super.foo();

  @override
  int get value => super.value;
}
''',
      [lint(83, 38), lint(125, 41)],
    );
  }
}
