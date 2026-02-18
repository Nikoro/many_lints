import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_border_all.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidBorderAllTest));
}

@reflectiveTest
class AvoidBorderAllTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidBorderAll();
    newPackage('flutter').addFile('lib/painting.dart', r'''
class Color {
  const Color(int value);
}

enum BorderStyle { none, solid }

class BorderSide {
  const BorderSide({
    Color color = const Color(0xFF000000),
    double width = 1.0,
    BorderStyle style = BorderStyle.solid,
  });
}

class Border {
  const Border.fromBorderSide(BorderSide side);
  static Border all({
    Color color = const Color(0xFF000000),
    double width = 1.0,
    BorderStyle style = BorderStyle.solid,
  }) => Border.fromBorderSide(BorderSide(color: color, width: width, style: style));
}
''');
    super.setUp();
  }

  Future<void> test_borderAll_noArgs() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final border = Border.all();
''',
      [lint(55, 12)],
    );
  }

  Future<void> test_borderAll_withColor() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final border = Border.all(color: Color(0xFF000000));
''',
      [lint(55, 36)],
    );
  }

  Future<void> test_borderAll_withAllArgs() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final border = Border.all(
  color: Color(0xFF000000),
  width: 1.0,
  style: BorderStyle.solid,
);
''',
      [lint(55, 83)],
    );
  }

  Future<void> test_borderFromBorderSide() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';
final border = Border.fromBorderSide(BorderSide());
''');
  }

  Future<void> test_borderFromBorderSide_withArgs() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';
final border = Border.fromBorderSide(
  BorderSide(color: Color(0xFF000000), width: 1.0, style: BorderStyle.solid),
);
''');
  }
}
