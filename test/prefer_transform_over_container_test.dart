import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_transform_over_container.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferTransformOverContainerTest),
  );
}

@reflectiveTest
class PreferTransformOverContainerTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferTransformOverContainer();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {}
class Key {}
class AlignmentGeometry {}
class Matrix4 {
  static Matrix4 identity() => Matrix4._();
  Matrix4._();
  Matrix4 skewY(double alpha) => this;
  Matrix4 rotateZ(double angle) => this;
}
class Container extends Widget {
  Container({Key? key, Matrix4? transform, AlignmentGeometry? alignment, Widget? child, double? width, double? height});
}
class Transform extends Widget {
  Transform({Key? key, required Matrix4 transform, Widget? child});
}
''');
    super.setUp();
  }

  Future<void> test_containerWithOnlyTransform() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(transform: Matrix4.identity());
}
''',
      [lint(61, 9)],
    );
  }

  Future<void> test_containerWithTransformAndChild() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(transform: Matrix4.identity(), child: Container());
}
''',
      [lint(61, 9)],
    );
  }

  Future<void> test_containerWithTransformAndKey() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(key: Key(), transform: Matrix4.identity());
}
''',
      [lint(61, 9)],
    );
  }

  Future<void> test_containerWithTransformAndAlignment() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(transform: Matrix4.identity(), alignment: Alignment.topRight);
}

class Alignment implements AlignmentGeometry {
  static const Alignment topRight = Alignment();
  const Alignment();
}
''');
  }

  Future<void> test_containerWithTransformAndWidth() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(transform: Matrix4.identity(), width: 100);
}
''');
  }

  Future<void> test_containerWithNoTransform() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(width: 100);
}
''');
  }

  Future<void> test_transformWidget() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Transform(transform: Matrix4.identity());
}
''');
  }
}
