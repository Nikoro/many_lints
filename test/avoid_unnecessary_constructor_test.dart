import 'package:many_lints/src/rules/avoid_unnecessary_constructor.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidUnnecessaryConstructorTest),
  );
}

@reflectiveTest
class AvoidUnnecessaryConstructorTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryConstructor();
    super.setUp();
  }

  Future<void> test_emptyUnnamedConstructor() async {
    await assertDiagnostics(
      r'''
class A {
  A();
}
''',
      [lint(12, 4)],
    );
  }

  Future<void> test_emptyConstructorWithBody() async {
    await assertDiagnostics(
      r'''
class A {
  A() {}
}
''',
      [lint(12, 6)],
    );
  }

  Future<void> test_constConstructorEnablesConstCallSites() async {
    await assertNoDiagnostics(r'''
class A {
  const A();
}
''');
  }

  Future<void> test_constructorWithParameters() async {
    await assertNoDiagnostics(r'''
class A {
  final int x;
  A(this.x);
}
''');
  }

  Future<void> test_namedConstructor() async {
    await assertNoDiagnostics(r'''
class A {
  A.named();
}
''');
  }

  Future<void> test_noConstructorDeclared() async {
    await assertNoDiagnostics(r'''
class A {}
''');
  }

  Future<void> test_secondConstructorKeepsTheUnnamedOneNecessary() async {
    await assertNoDiagnostics(r'''
class A {
  A();
  A.named();
}
''');
  }

  Future<void> test_documentedConstructorCarriesInformation() async {
    await assertNoDiagnostics(r'''
class A {
  /// Creates an empty A.
  A();
}
''');
  }

  Future<void> test_annotatedConstructor() async {
    await assertNoDiagnostics(r'''
class A {
  @deprecated
  A();
}
''');
  }

  Future<void> test_constructorWithInitializer() async {
    await assertNoDiagnostics(r'''
class A {
  final int x;
  A() : x = 1;
}
''');
  }
}
