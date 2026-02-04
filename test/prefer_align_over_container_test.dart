import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_align_over_container.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferAlignOverContainerTest),
  );
}

@reflectiveTest
class PreferAlignOverContainerTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferAlignOverContainer();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {}
class Key {}
class AlignmentGeometry {}
class Alignment implements AlignmentGeometry {
  static const Alignment center = Alignment(0, 0);
  static const Alignment topLeft = Alignment(-1, -1);
  const Alignment(double x, double y);
}
class Container extends Widget {
  Container({Key? key, AlignmentGeometry? alignment, Widget? child, double? width, double? height, EdgeInsets? margin});
}
class Align extends Widget {
  Align({Key? key, AlignmentGeometry? alignment, Widget? child});
}
class EdgeInsets {
  static const EdgeInsets zero = EdgeInsets.all(0);
  const EdgeInsets.all(double value);
}
''');
    super.setUp();
  }

  Future<void> test_containerWithOnlyAlignment() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(alignment: Alignment.center);
}
''',
      [lint(61, 9)],
    );
  }

  Future<void> test_containerWithAlignmentAndChild() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(alignment: Alignment.center, child: Container());
}
''',
      [lint(61, 9)],
    );
  }

  Future<void> test_containerWithAlignmentAndKey() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(key: Key(), alignment: Alignment.center);
}
''',
      [lint(61, 9)],
    );
  }

  Future<void> test_containerWithMultipleParams() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(alignment: Alignment.center, width: 100);
}
''');
  }

  Future<void> test_containerWithNoAlignment() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(width: 100);
}
''');
  }
}
