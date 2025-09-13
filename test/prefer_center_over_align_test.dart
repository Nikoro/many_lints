import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_center_over_align.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
      () => defineReflectiveTests(PreferCenterOverAlignTest));
}

@reflectiveTest
class PreferCenterOverAlignTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferCenterOverAlign();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {}
class Align extends Widget {
  Align({AlignmentGeometry? alignment});
}
class AlignmentGeometry {}
class Alignment implements AlignmentGeometry {
  static const Alignment center = Alignment(0, 0);
  static const Alignment topLeft = Alignment(-1, -1);
  const Alignment(double x, double y);
}
class Center extends Widget {}
''');
    super.setUp();
  }

  Future<void> test_alignmentCenter() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Align(alignment: Alignment.center);
}
''',
      [lint(61, 5)],
    );
  }

  Future<void> test_alignmentCenter_const() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Align(alignment: Alignment(0, 0));
}
''',
      [lint(61, 5)],
    );
  }

  Future<void> test_noAlignment() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Align();
}
''',
      [lint(61, 5)],
    );
  }

  Future<void> test_validAlignment() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Align(alignment: Alignment.topLeft);
}
''');
  }
}
