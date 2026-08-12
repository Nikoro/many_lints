import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/prefer_shorthands_with_enums.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferShorthandsWithEnumsTest),
  );
}

@reflectiveTest
class PreferShorthandsWithEnumsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferShorthandsWithEnums();
    newPackage('myenums').addFile('lib/myenums.dart', r'''
enum MyEnum { first, second }
''');
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

  Future<void> test_propertyAccessViaImportPrefix() async {
    await assertNoDiagnostics(r'''
import 'package:myenums/myenums.dart' as prefix;

void fn() {
  // prefix.MyEnum.first is PropertyAccess — target is PrefixedIdentifier,
  // not SimpleIdentifier, so the rule correctly skips it.
  final value = prefix.MyEnum.first;
}
''');
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
    await assertDiagnostics(
      r'''
enum MyEnum { first, second }

void fn({required MyEnum value}) {}

void caller() {
  fn(value: MyEnum.first);
}
''',
      [lint(96, 12)],
    );
  }

  Future<void> test_namedArgumentInConstructor() async {
    await assertDiagnostics(
      r'''
enum MainAxisSize { min, max }
enum CrossAxisAlignment { start, stretch }

class Column {
  Column({
    required MainAxisSize mainAxisSize,
    required CrossAxisAlignment crossAxisAlignment,
  });
}

Column caller() {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
  );
}
''',
      [lint(255, 16), lint(297, 26)],
    );
  }

  Future<void> test_namedArgument_dynamicParameter() async {
    await assertNoDiagnostics(r'''
enum MyEnum { first, second }

void fn({required dynamic value}) {}

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

  // --- type_inference.dart coverage: Set literal (line 71 - SetOrMapLiteral) ---

  Future<void> test_setLiteral() async {
    await assertDiagnostics(
      r'''
enum MyEnum { first, second }

void fn() {
  final Set<MyEnum> items = {MyEnum.first};
}
''',
      [lint(72, 12)],
    );
  }

  // --- collection literals without a downward context type ---
  // A literal in a `dynamic`/`Object?` position gets its static type inferred
  // upward from its own elements, which is not a context type. Reporting there
  // produces uncompilable code (`dot_shorthand_missing_context`).

  Future<void> test_listLiteral_dynamicParameter_notReported() async {
    await assertNoDiagnostics(r'''
enum MyEnum { first, second }

void expect(dynamic actual, dynamic matcher) {}
dynamic equals(Object? expected) => expected;

void fn(List<MyEnum> rankings) {
  expect(rankings, equals([MyEnum.first]));
}
''');
  }

  Future<void> test_listLiteral_objectNullableParameter_notReported() async {
    await assertNoDiagnostics(r'''
enum MyEnum { first, second }

void takes(Object? value) {}

void fn() {
  takes([MyEnum.first]);
}
''');
  }

  Future<void> test_setLiteral_dynamicParameter_notReported() async {
    await assertNoDiagnostics(r'''
enum MyEnum { first, second }

void takes(dynamic value) {}

void fn() {
  takes({MyEnum.first});
}
''');
  }

  Future<void> test_listLiteral_explicitTypeArgument() async {
    // The user wrote the type argument, so it is a genuine context type and
    // `<MyEnum>[.first]` compiles.
    await assertDiagnostics(
      r'''
enum MyEnum { first, second }

void takes(dynamic value) {}

void fn() {
  takes(<MyEnum>[MyEnum.first]);
}
''',
      [lint(90, 12)],
    );
  }

  Future<void> test_nestedListLiteral_typedContext() async {
    await assertDiagnostics(
      r'''
enum MyEnum { first, second }

void fn() {
  final List<List<MyEnum>> nested = [[MyEnum.first]];
}
''',
      [lint(81, 12)],
    );
  }

  Future<void> test_listLiteral_typedNamedArgument() async {
    await assertDiagnostics(
      r'''
enum MyEnum { first, second }

void takes({required List<MyEnum> items}) {}

void fn() {
  takes(items: [MyEnum.first]);
}
''',
      [lint(105, 12)],
    );
  }

  Future<void> test_genericParameter_inferredFromArgument_notReported() async {
    // `T` is solved *from* the element, so `List<MyEnum>` is an upward
    // inference, not a context type. `Box(items: const [.first])` does not
    // compile.
    await assertNoDiagnostics(r'''
enum MyEnum { first, second }

class Box<T> {
  const Box({required this.items});
  final List<T> items;
}

void fn() {
  Box(items: const [MyEnum.first]);
}
''');
  }

  Future<void> test_genericParameter_bareTypeVariable_notReported() async {
    await assertNoDiagnostics(r'''
enum MyEnum { first, second }

void takes<T>({required T value}) {}

void fn() {
  takes(value: MyEnum.first);
}
''');
  }

  Future<void> test_genericParameter_explicitTypeArgument() async {
    // The user pinned `T`, so the parameter really does impose a context type.
    await assertDiagnostics(
      r'''
enum MyEnum { first, second }

class Box<T> {
  const Box({required this.items});
  final List<T> items;
}

void fn() {
  Box<MyEnum>(items: const [MyEnum.first]);
}
''',
      [lint(148, 12)],
    );
  }

  Future<void> test_mapLiteral_keyPosition() async {
    await assertDiagnostics(
      r'''
enum MyEnum { first, second }

void fn() {
  final Map<MyEnum, String> m = {MyEnum.first: 'a'};
}
''',
      [lint(76, 12)],
    );
  }

  Future<void> test_mapLiteral_valuePosition() async {
    // The value half must resolve to the second type argument, not the key.
    await assertDiagnostics(
      r'''
enum MyEnum { first, second }

void fn() {
  final Map<String, MyEnum> m = {'a': MyEnum.first};
}
''',
      [lint(81, 12)],
    );
  }

  Future<void> test_mapLiteral_valueAgainstKeyType_notReported() async {
    // Only the key half may use a shorthand here: the value's context is
    // `Object`, so `MyEnum.second` must be left alone.
    await assertDiagnostics(
      r'''
enum MyEnum { first, second }

void fn() {
  final Map<MyEnum, Object> m = {MyEnum.first: MyEnum.second};
}
''',
      [lint(76, 12)],
    );
  }

  Future<void> test_mapLiteral_dynamicParameter_notReported() async {
    await assertNoDiagnostics(r'''
enum MyEnum { first, second }

void takes(dynamic value) {}

void fn() {
  takes({MyEnum.first: 'a'});
}
''');
  }

  // --- type_inference.dart coverage: resolveReturnType via MethodDeclaration ---

  Future<void> test_returnInMethodDeclaration() async {
    await assertDiagnostics(
      r'''
enum MyEnum { first, second }

class Foo {
  MyEnum getVal() {
    return MyEnum.first;
  }
}
''',
      [lint(74, 12)],
    );
  }

  // --- type_inference.dart coverage: resolveReturnType via ExpressionFunctionBody in method ---

  Future<void> test_expressionBodyInMethodDeclaration() async {
    await assertDiagnostics(
      r'''
enum MyEnum { first, second }

class Foo {
  MyEnum getVal() => MyEnum.first;
}
''',
      [lint(64, 12)],
    );
  }
}
