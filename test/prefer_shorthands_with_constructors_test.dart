import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/prefer_shorthands_with_constructors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferShorthandsWithConstructorsTest),
  );
}

@reflectiveTest
class PreferShorthandsWithConstructorsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferShorthandsWithConstructors();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {}

class EdgeInsets extends EdgeInsetsGeometry {
  const EdgeInsets.all(double value);
  const EdgeInsets.symmetric({double vertical = 0, double horizontal = 0});
  const EdgeInsets.only({double left = 0, double top = 0, double right = 0, double bottom = 0});
  static const EdgeInsets zero = EdgeInsets.all(0);
  static EdgeInsets lerp(EdgeInsets? a, EdgeInsets? b, double t) => EdgeInsets.all(0);
}

class BorderRadius {
  const BorderRadius.circular(double radius);
  const BorderRadius.all(Radius radius);
  static BorderRadius lerp(BorderRadius? a, BorderRadius? b, double t) => BorderRadius.circular(0);
}

class Radius {
  const Radius.circular(double radius);
}

abstract class ShapeBorder {
  const ShapeBorder();
}

class Border extends ShapeBorder {
  const Border();
  const Border.all({required Color color, double width = 1.0});
}

abstract class EdgeInsetsGeometry {
  const EdgeInsetsGeometry();
  const factory EdgeInsetsGeometry.all(double value) = EdgeInsets.all;
  const factory EdgeInsetsGeometry.only({double left, double top, double right, double bottom}) = EdgeInsets.only;
  factory EdgeInsetsGeometry.symmetric({double vertical = 0, double horizontal = 0}) => EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal);
  static EdgeInsetsGeometry lerp(EdgeInsets? a, EdgeInsets? b, double t) => EdgeInsets.all(0);
}

class EdgeInsetsDirectional extends EdgeInsetsGeometry {
  const EdgeInsetsDirectional.only({double start = 0, double top = 0, double end = 0, double bottom = 0});
}

void takePaddings(List<EdgeInsets> paddings) {}

class ExpansionTile extends Widget {
  ExpansionTile({ShapeBorder? shape, EdgeInsetsGeometry? tilePadding});
}

class Color {
  const Color(int value);
}

class Padding extends Widget {
  Padding({required EdgeInsets padding});
}

class BoxDecoration {
  BoxDecoration({BorderRadius? borderRadius, Border? border});
}

class Container extends Widget {
  Container({EdgeInsets? padding, BoxDecoration? decoration});
}
''');
    super.setUp();
  }

  Future<void> test_edgeInsetsSymmetric_namedArgument() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Widget f() {
  return Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12));
}
''',
      [lint(79, 20)],
    );
  }

  Future<void> test_edgeInsetsAll_namedArgument() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Widget f() {
  return Padding(padding: EdgeInsets.all(8));
}
''',
      [lint(79, 14)],
    );
  }

  Future<void> test_borderRadiusCircular_namedArgument() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

void f() {
  final decoration = BoxDecoration(borderRadius: BorderRadius.circular(18));
}
''',
      [lint(100, 21)],
    );
  }

  Future<void> test_borderAll_namedArgument() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

void f() {
  final decoration = BoxDecoration(border: Border.all(color: Color(0xFF000000), width: 2));
}
''',
      [lint(94, 10)],
    );
  }

  Future<void> test_radiusCircular_namedArgument() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

void f() {
  final borderRadius = BorderRadius.all(Radius.circular(8));
}
''',
      [lint(91, 15)],
    );
  }

  Future<void> test_multipleConstructors_inSameWidget() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Widget f() {
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Color(0xFF000000)),
    ),
  );
}
''',
      [lint(86, 14), lint(157, 21), lint(198, 10)],
    );
  }

  Future<void> test_alreadyUsingShorthand() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget f() {
  return Padding(padding: .symmetric(horizontal: 16, vertical: 12));
}
''');
  }

  Future<void> test_notUsedAsArgument_variableDeclaration() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void f() {
  final EdgeInsets padding = EdgeInsets.all(8);
}
''');
  }

  Future<void> test_notUsedAsArgument_assignment() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void f() {
  EdgeInsets padding;
  padding = EdgeInsets.all(8);
}
''');
  }

  Future<void> test_notConfiguredClass() async {
    await assertNoDiagnostics(r'''
class MyClass {
  MyClass.named();
}

void f({required MyClass obj}) {
  final result = f(obj: MyClass.named());
}
''');
  }

  Future<void> test_defaultConstructor() async {
    await assertNoDiagnostics(r'''
class MyClass {
  const MyClass();
}

void f({required MyClass obj}) {
  final result = f(obj: MyClass());
}
''');
  }

  Future<void> test_typeNotInferable_dynamicParameter() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void f(dynamic padding) {}

void caller() {
  f(EdgeInsets.all(8));
}
''');
  }

  Future<void> test_inListLiteral() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

void f() {
  final List<EdgeInsets> list = [EdgeInsets.all(8), EdgeInsets.symmetric(horizontal: 16)];
}
''',
      [lint(84, 14), lint(103, 20)],
    );
  }

  Future<void> test_parenthesizedExpression() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Widget f() {
  return Padding(padding: (EdgeInsets.all(8)));
}
''',
      [lint(80, 14)],
    );
  }

  Future<void> test_edgeInsetsOnly_namedArgument() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Widget f() {
  return Padding(padding: EdgeInsets.only(left: 8, top: 8));
}
''',
      [lint(79, 15)],
    );
  }

  Future<void> test_constConstructor() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Widget f() {
  return Padding(padding: const EdgeInsets.all(8));
}
''',
      [lint(85, 14)],
    );
  }

  Future<void> test_in_list_literal() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

void f() {
  final List<EdgeInsets> paddings = [EdgeInsets.all(8), EdgeInsets.all(16)];
}
''',
      [lint(88, 14), lint(107, 14)],
    );
  }

  Future<void> test_method_invocation_in_list() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

void f() {
  final List<EdgeInsets> items = [EdgeInsets.symmetric(horizontal: 8)];
}
''',
      [lint(85, 20)],
    );
  }

  Future<void> test_staticMethod_namedArgument() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Widget f() {
  return Padding(padding: EdgeInsets.lerp(null, null, 0.5));
}
''',
      [lint(79, 10)],
    );
  }

  Future<void> test_staticMethod_notConfiguredClass() async {
    await assertNoDiagnostics(r'''
class Foo {
  static Foo create() => Foo();
}

void f({required Foo foo}) {
  f(foo: Foo.create());
}
''');
  }

  Future<void> test_staticMethod_notUsedAsArgument() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void f() {
  final result = EdgeInsets.lerp(null, null, 0.5);
}
''');
  }

  Future<void> test_staticMethod_inListLiteral() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

void f() {
  final List<EdgeInsets> items = [EdgeInsets.lerp(null, null, 0.5)];
}
''',
      [lint(85, 10)],
    );
  }

  Future<void> test_inSetLiteral() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

void f() {
  final Set<EdgeInsets> items = {EdgeInsets.all(8)};
}
''',
      [lint(84, 14)],
    );
  }

  Future<void> test_staticMethod_inSetLiteral() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

void f() {
  final Set<EdgeInsets> items = {EdgeInsets.lerp(null, null, 0.5)};
}
''',
      [lint(84, 10)],
    );
  }

  Future<void> test_staticMethod_borderRadius_namedArgument() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

void f() {
  final decoration = BoxDecoration(borderRadius: BorderRadius.lerp(null, null, 0.5));
}
''',
      [lint(100, 12)],
    );
  }

  Future<void>
  test_abstractSupertypeParameterWithoutTheConstructor_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget f() {
  return ExpansionTile(shape: const Border());
}
''');
  }

  Future<void> test_supertypeParameterWithTheConstructor_lints() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Widget f() {
  return ExpansionTile(tilePadding: EdgeInsets.all(8));
}
''',
      [lint(89, 14)],
    );
  }

  Future<void> test_objectParameter_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void take(Object value) {}

void f() {
  take(const Border());
}
''');
  }

  Future<void>
  test_supertypeFactoryRedirectingWithoutTheNamedParameter_noLint() async {
    newFile(
      '$testPackageRootPath/many_lints.yaml',
      'rules:\n  prefer_shorthands_with_constructors:\n    additional_classes: [EdgeInsetsDirectional]\n',
    );
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget f() {
  return ExpansionTile(tilePadding: EdgeInsetsDirectional.only(start: 8));
}
''');
  }

  Future<void>
  test_supertypeFactoryRedirectingToTheSameConstructor_lints() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Widget f() {
  return ExpansionTile(tilePadding: EdgeInsets.only(left: 8));
}
''',
      [lint(89, 15)],
    );
  }

  Future<void> test_supertypeNonRedirectingFactory_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget f() {
  return ExpansionTile(tilePadding: EdgeInsets.symmetric(horizontal: 8));
}
''');
  }

  Future<void> test_supertypeStaticMethod_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget f() {
  return ExpansionTile(tilePadding: EdgeInsets.lerp(null, null, 0.5));
}
''');
  }

  Future<void> test_untypedListLiteralWithoutContextType_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void f() {
  final paddings = [EdgeInsets.all(8)];
  final unique = {EdgeInsets.all(8)};
}
''');
  }

  Future<void> test_explicitlyTypedListLiteral_lints() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

void f() {
  final paddings = <EdgeInsets>[EdgeInsets.all(8)];
}
''',
      [lint(83, 14)],
    );
  }

  Future<void> test_listLiteralArgument_lints() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

void f() {
  takePaddings([EdgeInsets.all(8)]);
}
''',
      [lint(67, 14)],
    );
  }
}
