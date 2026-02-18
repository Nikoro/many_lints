import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_const_border_radius.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferConstBorderRadiusTest),
  );
}

@reflectiveTest
class PreferConstBorderRadiusTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferConstBorderRadius();
    newPackage('flutter').addFile('lib/painting.dart', r'''
class Radius {
  const Radius.circular(double radius);
}

class BorderRadius {
  const BorderRadius.all(Radius radius);
  static BorderRadius circular(double radius) =>
      BorderRadius.all(Radius.circular(radius));
}
''');
    super.setUp();
  }

  Future<void> test_borderRadiusCircular() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final radius = BorderRadius.circular(8);
''',
      [lint(55, 24)],
    );
  }

  Future<void> test_borderRadiusCircular_doubleArg() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final radius = BorderRadius.circular(8.0);
''',
      [lint(55, 26)],
    );
  }

  Future<void> test_borderRadiusCircular_variableArg() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
void f(double r) {
  final radius = BorderRadius.circular(r);
}
''',
      [lint(76, 24)],
    );
  }

  Future<void> test_borderRadiusAll() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';
final radius = BorderRadius.all(Radius.circular(8));
''');
  }

  Future<void> test_constBorderRadiusAll() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';
const radius = BorderRadius.all(Radius.circular(8));
''');
  }
}
