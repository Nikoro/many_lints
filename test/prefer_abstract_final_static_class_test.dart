import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_abstract_final_static_class.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferAbstractFinalStaticClassTest),
  );
}

@reflectiveTest
class PreferAbstractFinalStaticClassTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferAbstractFinalStaticClass();
    super.setUp();
  }

  // --- Positive cases (should trigger lint) ---

  Future<void> test_classWithOnlyStaticFields() async {
    await assertDiagnostics(
      r'''
class Constants {
  static const name = 'app';
  static final version = '1.0';
}
''',
      [lint(0, 80)],
    );
  }

  Future<void> test_classWithOnlyStaticMethods() async {
    await assertDiagnostics(
      r'''
class Utils {
  static int add(int a, int b) => a + b;
  static int multiply(int a, int b) => a * b;
}
''',
      [lint(0, 102)],
    );
  }

  Future<void> test_classWithMixedStaticMembers() async {
    await assertDiagnostics(
      r'''
class Helper {
  static const value = 42;
  static void doSomething() {}
}
''',
      [lint(0, 74)],
    );
  }

  Future<void> test_classAlreadyAbstractButNotFinal() async {
    await assertDiagnostics(
      r'''
abstract class Static {
  static final field = 'value';
}
''',
      [lint(0, 57)],
    );
  }

  Future<void> test_classAlreadyFinalButNotAbstract() async {
    await assertDiagnostics(
      r'''
final class Static {
  static final field = 'value';
}
''',
      [lint(0, 54)],
    );
  }

  // --- Negative cases (should NOT trigger lint) ---

  Future<void> test_abstractFinalClass() async {
    await assertNoDiagnostics(r'''
abstract final class Constants {
  static const name = 'app';
}
''');
  }

  Future<void> test_classWithInstanceField() async {
    await assertNoDiagnostics(r'''
class MyClass {
  final String value;
  static const name = 'app';
  MyClass(this.value);
}
''');
  }

  Future<void> test_classWithInstanceMethod() async {
    await assertNoDiagnostics(r'''
class MyClass {
  static const name = 'app';
  void doSomething() {}
}
''');
  }

  Future<void> test_classWithConstructor() async {
    await assertNoDiagnostics(r'''
class MyClass {
  static const name = 'app';
  MyClass();
}
''');
  }

  Future<void> test_emptyClass() async {
    await assertNoDiagnostics(r'''
class Empty {}
''');
  }

  Future<void> test_sealedClass() async {
    await assertNoDiagnostics(r'''
sealed class MySealedClass {
  static const name = 'app';
}
''');
  }

  Future<void> test_baseClass() async {
    await assertNoDiagnostics(r'''
base class MyBaseClass {
  static const name = 'app';
}
''');
  }

  Future<void> test_interfaceClass() async {
    await assertNoDiagnostics(r'''
interface class MyInterfaceClass {
  static const name = 'app';
}
''');
  }

  Future<void> test_mixinClass() async {
    await assertNoDiagnostics(r'''
mixin class MyMixinClass {
  static const name = 'app';
}
''');
  }
}
