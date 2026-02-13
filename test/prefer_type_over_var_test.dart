import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_type_over_var.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferTypeOverVarTest));
}

@reflectiveTest
class PreferTypeOverVarTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferTypeOverVar();
    super.setUp();
  }

  Future<void> test_localVariable() async {
    await assertDiagnostics(
      r'''
void fn() {
  var x = 42;
}
''',
      [lint(14, 3)],
    );
  }

  Future<void> test_localVariableNullable() async {
    await assertDiagnostics(
      r'''
String? nullableMethod() => null;

void fn() {
  var variable = nullableMethod();
}
''',
      [lint(49, 3)],
    );
  }

  Future<void> test_topLevelVariable() async {
    await assertDiagnostics(
      r'''
var topLevel = 'hello';
''',
      [lint(0, 3)],
    );
  }

  Future<void> test_topLevelVariableNullable() async {
    await assertDiagnostics(
      r'''
String? nullableMethod() => null;

var topLevelVariable = nullableMethod();
''',
      [lint(35, 3)],
    );
  }

  Future<void> test_multipleVariables() async {
    await assertDiagnostics(
      r'''
void fn() {
  var x = 1, y = 2;
}
''',
      [lint(14, 3)],
    );
  }

  Future<void> test_insideClass() async {
    await assertDiagnostics(
      r'''
class SomeClass {
  void method() {
    var variable = 'test';
  }
}
''',
      [lint(40, 3)],
    );
  }

  // Negative test cases - should NOT trigger

  Future<void> test_finalVariable() async {
    await assertNoDiagnostics(r'''
void fn() {
  final x = 42;
}
''');
  }

  Future<void> test_constVariable() async {
    await assertNoDiagnostics(r'''
void fn() {
  const x = 42;
}
''');
  }

  Future<void> test_explicitType() async {
    await assertNoDiagnostics(r'''
void fn() {
  int x = 42;
}
''');
  }

  Future<void> test_explicitNullableType() async {
    await assertNoDiagnostics(r'''
String? nullableMethod() => null;

void fn() {
  String? variable = nullableMethod();
}
''');
  }

  Future<void> test_topLevelExplicitType() async {
    await assertNoDiagnostics(r'''
String topLevel = 'hello';
''');
  }

  Future<void> test_topLevelFinal() async {
    await assertNoDiagnostics(r'''
final topLevel = 'hello';
''');
  }

  Future<void> test_topLevelConst() async {
    await assertNoDiagnostics(r'''
const topLevel = 'hello';
''');
  }

  Future<void> test_forLoopVariable() async {
    await assertDiagnostics(
      r'''
void fn() {
  for (var i = 0; i < 10; i++) {
    print(i);
  }
}
''',
      [lint(19, 3)],
    );
  }

  Future<void> test_inferredComplexType() async {
    await assertDiagnostics(
      r'''
void fn() {
  var list = [1, 2, 3];
}
''',
      [lint(14, 3)],
    );
  }
}
