import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_unrelated_type_casts.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidUnrelatedTypeCastsTest),
  );
}

@reflectiveTest
class AvoidUnrelatedTypeCastsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnrelatedTypeCasts();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_castBetweenUnrelatedCoreTypes() async {
    await assertDiagnostics(
      r'''
int f(String value) => value as int;
''',
      [lint(23, 12)],
    );
  }

  Future<void> test_isCheckBetweenUnrelatedCoreTypes() async {
    await assertDiagnostics(
      r'''
bool f(String value) => value is int;
''',
      [lint(24, 12)],
    );
  }

  Future<void> test_castBetweenUnrelatedEnums() async {
    await assertDiagnostics(
      r'''
enum Color { red }

enum Size { big }

Size f(Color value) => value as Size;
''',
      [lint(62, 13)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_downcastInHierarchy() async {
    await assertNoDiagnostics(r'''
class Animal {}

class Dog extends Animal {}

Dog f(Animal value) => value as Dog;
''');
  }

  Future<void> test_upcastInHierarchy() async {
    await assertNoDiagnostics(r'''
class Animal {}

class Dog extends Animal {}

Animal f(Dog value) => value as Animal;
''');
  }

  Future<void> test_castFromDynamic() async {
    await assertNoDiagnostics(r'''
int f(dynamic value) => value as int;
''');
  }

  Future<void> test_castFromObject() async {
    await assertNoDiagnostics(r'''
int f(Object value) => value as int;
''');
  }

  Future<void> test_nullabilityOnlyDifference() async {
    await assertNoDiagnostics(r'''
String f(String? value) => value as String;
''');
  }

  // ---- Edge cases ----

  Future<void> test_openClassesCouldShareSubtype() async {
    await assertNoDiagnostics(r'''
class Foo {}

class Bar {}

Bar f(Foo value) => value as Bar;
''');
  }

  Future<void> test_typeParameterIsIgnored() async {
    await assertNoDiagnostics(r'''
T f<T>(Object value) => value as T;
''');
  }

  Future<void> test_finalClassesCannotShareSubtype() async {
    await assertDiagnostics(
      r'''
final class Foo {}

final class Bar {}

Bar f(Foo value) => value as Bar;
''',
      [lint(60, 12)],
    );
  }
}
