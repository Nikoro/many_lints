import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_shorthands_with_enums.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferShorthandsWithEnumsTest),
  );
}

@reflectiveTest
class PreferShorthandsWithEnumsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferShorthandsWithEnums();
    super.setUp();
  }

  Future<void> test_switchCase() async {
    await assertDiagnostics(
      r'''
enum MyEnum { first, second }

void fn(MyEnum? e) {
  switch (e) {
    case MyEnum.first:
      print(e);
    default:
      break;
  }
}
''',
      [lint(76, 12)],
    );
  }

  Future<void> test_switchExpressionPattern() async {
    await assertDiagnostics(
      r'''
enum MyEnum { first, second }

void fn(MyEnum? e) {
  final v = switch (e) {
    MyEnum.first => 1,
    _ => 2,
  };
}
''',
      [lint(81, 12)],
    );
  }

  Future<void> test_variableDeclaration() async {
    await assertDiagnostics(
      r'''
enum MyEnum { first, second }

void fn() {
  final MyEnum another = MyEnum.first;
}
''',
      [lint(68, 12)],
    );
  }

  Future<void> test_binaryExpression() async {
    await assertDiagnostics(
      r'''
enum MyEnum { first, second }

void fn(MyEnum? e) {
  if (e == MyEnum.first) {}
}
''',
      [lint(63, 12)],
    );
  }

  Future<void> test_defaultParameter() async {
    await assertDiagnostics(
      r'''
enum MyEnum { first, second }

void another({MyEnum value = MyEnum.first}) {}
''',
      [lint(60, 12)],
    );
  }

  Future<void> test_expressionFunctionBody() async {
    await assertDiagnostics(
      r'''
enum MyEnum { first, second }

MyEnum getEnum() => MyEnum.first;
''',
      [lint(51, 12)],
    );
  }

  Future<void> test_returnStatement() async {
    await assertDiagnostics(
      r'''
enum MyEnum { first, second }

MyEnum getEnum() {
  return MyEnum.first;
}
''',
      [lint(59, 12)],
    );
  }

  Future<void> test_alreadyUsingShorthand() async {
    await assertNoDiagnostics(r'''
enum MyEnum { first, second }

void fn(MyEnum? e) {
  switch (e) {
    case .first:
      print(e);
    default:
      break;
  }
}
''');
  }

  Future<void> test_shorthandInVariableDeclaration() async {
    await assertNoDiagnostics(r'''
enum MyEnum { first, second }

void fn() {
  final MyEnum another = .first;
}
''');
  }

  Future<void> test_typeNotInferable() async {
    await assertNoDiagnostics(r'''
enum MyEnum { first, second }

Object getObject() => MyEnum.first;
''');
  }

  Future<void> test_notAnEnum() async {
    await assertNoDiagnostics(r'''
class MyClass {
  static const first = 1;
}

void fn() {
  final value = MyClass.first;
}
''');
  }

  Future<void> test_staticField() async {
    await assertNoDiagnostics(r'''
class MyClass {
  static const first = 1;
}

void fn() {
  print(MyClass.first);
}
''');
  }

  Future<void> test_assignment() async {
    await assertNoDiagnostics(r'''
enum MyEnum { first, second }

void fn() {
  MyEnum value;
  value = MyEnum.first;
}
''');
  }

  Future<void> test_listLiteral() async {
    await assertDiagnostics(
      r'''
enum MyEnum { first, second }

void fn() {
  final List<MyEnum> list = [MyEnum.first];
}
''',
      [lint(72, 12)],
    );
  }

  Future<void> test_namedArgument() async {
    await assertNoDiagnostics(r'''
enum MyEnum { first, second }

void fn({required MyEnum value}) {}

void caller() {
  fn(value: MyEnum.first);
}
''');
  }

  Future<void> test_comparisonLeftSide() async {
    await assertDiagnostics(
      r'''
enum MyEnum { first, second }

void fn(MyEnum? e) {
  if (MyEnum.first == e) {}
}
''',
      [lint(58, 12)],
    );
  }

  Future<void> test_nullableEnum() async {
    await assertDiagnostics(
      r'''
enum MyEnum { first, second }

void fn() {
  MyEnum? value = MyEnum.first;
}
''',
      [lint(61, 12)],
    );
  }

  Future<void> test_propertyAccess() async {
    await assertNoDiagnostics(r'''
enum MyEnum { first, second }

void fn() {
  final value = MyEnum.first;
}
''');
  }
}
