import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_shorthands_with_static_fields.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferShorthandsWithStaticFieldsTest));
}

@reflectiveTest
class PreferShorthandsWithStaticFieldsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferShorthandsWithStaticFields();
    super.setUp();
  }

  Future<void> test_switchCase() async {
    await assertDiagnostics(
      r'''
class SomeClass {
  final String value;
  const SomeClass(this.value);
  static const first = SomeClass('first');
  static const second = SomeClass('second');
}

void fn(SomeClass? e) {
  switch (e) {
    case SomeClass.first:
      print(e);
    default:
      break;
  }
}
''',
      [lint(210, 15)],
    );
  }

  Future<void> test_switchExpressionPattern() async {
    await assertDiagnostics(
      r'''
class SomeClass {
  final String value;
  const SomeClass(this.value);
  static const first = SomeClass('first');
  static const second = SomeClass('second');
}

void fn(SomeClass? e) {
  final v = switch (e) {
    SomeClass.first => 1,
    _ => 2,
  };
}
''',
      [lint(215, 15)],
    );
  }

  Future<void> test_variableDeclaration() async {
    await assertDiagnostics(
      r'''
class SomeClass {
  final String value;
  const SomeClass(this.value);
  static const first = SomeClass('first');
  static const second = SomeClass('second');
}

void fn() {
  final SomeClass another = SomeClass.first;
}
''',
      [lint(202, 15)],
    );
  }

  Future<void> test_binaryExpression() async {
    await assertDiagnostics(
      r'''
class SomeClass {
  final String value;
  const SomeClass(this.value);
  static const first = SomeClass('first');
  static const second = SomeClass('second');
}

void fn(SomeClass? e) {
  if (e == SomeClass.first) {}
}
''',
      [lint(197, 15)],
    );
  }

  Future<void> test_defaultParameter() async {
    await assertDiagnostics(
      r'''
class SomeClass {
  final String value;
  const SomeClass(this.value);
  static const first = SomeClass('first');
  static const second = SomeClass('second');
}

void another({SomeClass value = SomeClass.first}) {}
''',
      [lint(194, 15)],
    );
  }

  Future<void> test_expressionFunctionBody() async {
    await assertDiagnostics(
      r'''
class SomeClass {
  final String value;
  const SomeClass(this.value);
  static const first = SomeClass('first');
  static const second = SomeClass('second');
}

SomeClass getClass() => SomeClass.first;
''',
      [lint(186, 15)],
    );
  }

  Future<void> test_returnStatement() async {
    await assertDiagnostics(
      r'''
class SomeClass {
  final String value;
  const SomeClass(this.value);
  static const first = SomeClass('first');
  static const second = SomeClass('second');
}

SomeClass getClass() {
  return SomeClass.first;
}
''',
      [lint(194, 15)],
    );
  }

  Future<void> test_alreadyUsingShorthand() async {
    await assertNoDiagnostics(r'''
class SomeClass {
  final String value;
  const SomeClass(this.value);
  static const first = SomeClass('first');
  static const second = SomeClass('second');
}

void fn(SomeClass? e) {
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
class SomeClass {
  final String value;
  const SomeClass(this.value);
  static const first = SomeClass('first');
  static const second = SomeClass('second');
}

void fn() {
  final SomeClass another = .first;
}
''');
  }

  Future<void> test_typeNotInferable() async {
    await assertNoDiagnostics(r'''
class SomeClass {
  final String value;
  const SomeClass(this.value);
  static const first = SomeClass('first');
  static const second = SomeClass('second');
}

Object getObject() => SomeClass.first;
''');
  }

  Future<void> test_notAClass() async {
    await assertNoDiagnostics(r'''
enum MyEnum { first, second }

void fn(MyEnum? e) {
  if (e == MyEnum.first) {}
}
''');
  }

  Future<void> test_staticFieldNotSameType() async {
    await assertNoDiagnostics(r'''
class SomeClass {
  final String value;
  const SomeClass(this.value);
  static const String staticString = 'test';
}

void fn() {
  final String str = SomeClass.staticString;
}
''');
  }

  Future<void> test_nonStaticField() async {
    await assertNoDiagnostics(r'''
class SomeClass {
  final String value;
  const SomeClass(this.value);
  
  String getValue() => value;
}

void fn(SomeClass obj) {
  print(obj.getValue());
}
''');
  }

  Future<void> test_namedConstructorWithDifferentType() async {
    await assertNoDiagnostics(r'''
class Container {
  Container();
  static Container fromJson(Map<String, dynamic> json) => Container();
}

void fn() {
  final container = Container.fromJson({});
}
''');
  }
}
