import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_shorthands_with_constructors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferShorthandsWithConstructorsTest));
}

@reflectiveTest
class PreferShorthandsWithConstructorsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferShorthandsWithConstructors();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {}

class EdgeInsets {
  const EdgeInsets.all(double value);
  const EdgeInsets.symmetric({double vertical = 0, double horizontal = 0});
  const EdgeInsets.only({double left = 0, double top = 0, double right = 0, double bottom = 0});
  static const EdgeInsets zero = EdgeInsets.all(0);
}

class BorderRadius {
  const BorderRadius.circular(double radius);
  const BorderRadius.all(Radius radius);
}

class Radius {
  const Radius.circular(double radius);
}

class Border {
  const Border.all({required Color color, double width = 1.0});
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

  // Note: This lint cannot detect dynamic parameter types at compile time
  // The shorthand would still work, but we cannot verify the type
  Future<void> test_typeNotInferable_dynamicParameter() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

void f(dynamic padding) {}

void caller() {
  f(EdgeInsets.all(8));
}
''',
      [lint(88, 14)],
    );
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
}
