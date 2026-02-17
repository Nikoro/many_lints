import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_generics_shadowing.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidGenericsShadowingTest),
  );
}

@reflectiveTest
class AvoidGenericsShadowingTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidGenericsShadowing();
    super.setUp();
  }

  // --- Positive cases (should trigger lint) ---

  Future<void> test_classShadowsClass() async {
    await assertDiagnostics(
      r'''
class MyModel {}

class Repository<MyModel> {
  MyModel get(int id) => throw '';
}
''',
      [lint(35, 7)],
    );
  }

  Future<void> test_methodShadowsEnum() async {
    await assertDiagnostics(
      r'''
enum MyEnum { first, second }

class SomeClass {
  void method<MyEnum>(MyEnum p) {}
}
''',
      [lint(63, 6)],
    );
  }

  Future<void> test_methodShadowsClass() async {
    await assertDiagnostics(
      r'''
class AnotherClass {}

class SomeClass {
  AnotherClass anotherMethod<AnotherClass>() {
    throw '';
  }
}
''',
      [lint(70, 12)],
    );
  }

  Future<void> test_classShadowsMixin() async {
    await assertDiagnostics(
      r'''
mixin MyMixin {}

class Foo<MyMixin> {}
''',
      [lint(28, 7)],
    );
  }

  Future<void> test_classShadowsTypedef() async {
    await assertDiagnostics(
      r'''
typedef MyCallback = void Function();

class Foo<MyCallback> {}
''',
      [lint(49, 10)],
    );
  }

  Future<void> test_multipleShadowing() async {
    await assertDiagnostics(
      r'''
class A {}
class B {}

class Foo<A, B> {}
''',
      [lint(33, 1), lint(36, 1)],
    );
  }

  Future<void> test_functionShadowsClass() async {
    await assertDiagnostics(
      r'''
class Config {}

void process<Config>(Config c) {}
''',
      [lint(30, 6)],
    );
  }

  Future<void> test_typedefShadowsClass() async {
    await assertDiagnostics(
      r'''
class Value {}

typedef Transform<Value> = Value Function(Value);
''',
      [lint(34, 5)],
    );
  }

  // --- Negative cases (should NOT trigger lint) ---

  Future<void> test_noShadowing_singleLetter() async {
    await assertNoDiagnostics(r'''
class MyModel {}

class Repository<T> {
  T get(int id) => throw '';
}
''');
  }

  Future<void> test_noShadowing_differentName() async {
    await assertNoDiagnostics(r'''
class MyModel {}

class Repository<TModel> {
  TModel get(int id) => throw '';
}
''');
  }

  Future<void> test_noShadowing_noTopLevelTypes() async {
    await assertNoDiagnostics(r'''
void process<Config>(Config c) {}
''');
  }

  Future<void> test_noShadowing_multipleTypeParams() async {
    await assertNoDiagnostics(r'''
class MyModel {}

class Pair<T, R> {
  final T first;
  final R second;
  Pair(this.first, this.second);
}
''');
  }

  Future<void> test_noShadowing_enumWithMethod() async {
    await assertNoDiagnostics(r'''
enum Status { active, inactive }

class Processor<T> {
  void process(T item) {}
}
''');
  }
}
