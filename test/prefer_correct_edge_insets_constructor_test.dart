import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_correct_edge_insets_constructor.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferCorrectEdgeInsetsConstructorTest),
  );
}

@reflectiveTest
class PreferCorrectEdgeInsetsConstructorTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferCorrectEdgeInsetsConstructor();
    newPackage('flutter').addFile('lib/painting.dart', r'''
class EdgeInsets {
  const EdgeInsets.fromLTRB(double left, double top, double right, double bottom);
  const EdgeInsets.all(double value);
  const EdgeInsets.only({double left = 0, double top = 0, double right = 0, double bottom = 0});
  const EdgeInsets.symmetric({double horizontal = 0, double vertical = 0});
  static const EdgeInsets zero = EdgeInsets.all(0);
}

class EdgeInsetsHelper {
  static EdgeInsets fromLTRB(double left, double top, double right, double bottom) =>
      EdgeInsets.fromLTRB(left, top, right, bottom);
  static EdgeInsets only({double left = 0, double top = 0, double right = 0, double bottom = 0}) =>
      EdgeInsets.only(left: left, top: top, right: right, bottom: bottom);
  static EdgeInsets symmetric({double horizontal = 0, double vertical = 0}) =>
      EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  static EdgeInsets all(double value) => EdgeInsets.all(value);
}
''');
    super.setUp();
  }

  // === fromLTRB tests ===

  Future<void> test_fromLTRB_allEqual() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.fromLTRB(8, 8, 8, 8);
''',
      [lint(50, 31)],
    );
  }

  Future<void> test_fromLTRB_symmetric() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.fromLTRB(8, 0, 8, 0);
''',
      [lint(50, 31)],
    );
  }

  Future<void> test_fromLTRB_symmetricBoth() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.fromLTRB(8, 4, 8, 4);
''',
      [lint(50, 31)],
    );
  }

  Future<void> test_fromLTRB_onlyLeft() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.fromLTRB(8, 0, 0, 0);
''',
      [lint(50, 31)],
    );
  }

  Future<void> test_fromLTRB_onlyLeftAndTop() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.fromLTRB(8, 4, 0, 0);
''',
      [lint(50, 31)],
    );
  }

  Future<void> test_fromLTRB_allZero() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.fromLTRB(0, 0, 0, 0);
''',
      [lint(50, 31)],
    );
  }

  Future<void> test_fromLTRB_allDifferent_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.fromLTRB(1, 2, 3, 4);
''');
  }

  // === only tests ===

  Future<void> test_only_allEqual() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.only(left: 8, top: 8, right: 8, bottom: 8);
''',
      [lint(50, 53)],
    );
  }

  Future<void> test_only_symmetric() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.only(left: 16, right: 16);
''',
      [lint(50, 36)],
    );
  }

  Future<void> test_only_symmetricVertical() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.only(top: 8, bottom: 8);
''',
      [lint(50, 34)],
    );
  }

  Future<void> test_only_symmetricBoth() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.only(left: 8, top: 4, right: 8, bottom: 4);
''',
      [lint(50, 53)],
    );
  }

  Future<void> test_only_allZero() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.only(left: 0, top: 0, right: 0, bottom: 0);
''',
      [lint(50, 53)],
    );
  }

  Future<void> test_only_singleSide_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.only(left: 8);
''');
  }

  Future<void> test_only_twoSidesNotSymmetric_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.only(left: 8, top: 4);
''');
  }

  // === symmetric tests ===

  Future<void> test_symmetric_bothEqual() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.symmetric(horizontal: 8, vertical: 8);
''',
      [lint(50, 48)],
    );
  }

  Future<void> test_symmetric_bothZero() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.symmetric(horizontal: 0, vertical: 0);
''',
      [lint(50, 48)],
    );
  }

  Future<void> test_symmetric_different_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.symmetric(horizontal: 8, vertical: 4);
''');
  }

  Future<void> test_symmetric_onlyHorizontal_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.symmetric(horizontal: 8);
''');
  }

  Future<void> test_symmetric_onlyVertical_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.symmetric(vertical: 8);
''');
  }

  // === all tests ===

  Future<void> test_all_zero() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.all(0);
''',
      [lint(50, 17)],
    );
  }

  Future<void> test_all_zeroDouble() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.all(0.0);
''',
      [lint(50, 19)],
    );
  }

  Future<void> test_all_nonZero_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.all(8);
''');
  }

  // === EdgeInsets.zero should not lint ===

  Future<void> test_zero_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.zero;
''');
  }

  // === Variable arguments (should not lint for non-literal comparisons) ===

  Future<void> test_fromLTRB_variableArgs_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';
void f(double a, double b, double c, double d) {
  final p = EdgeInsets.fromLTRB(a, b, c, d);
}
''');
  }

  Future<void> test_fromLTRB_sameVariable_allEqual() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
void f(double v) {
  final p = EdgeInsets.fromLTRB(v, v, v, v);
}
''',
      [lint(71, 31)],
    );
  }

  Future<void> test_fromLTRB_symmetricVerticalOnly() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.fromLTRB(0, 8, 0, 8);
''',
      [lint(50, 31)],
    );
  }

  Future<void> test_methodInvocation_fromLTRB_allEqual() async {
    // Exercises visitMethodInvocation path (lines 66-77)
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.fromLTRB(8, 8, 8, 8);
''',
      [lint(50, 31)],
    );
  }

  Future<void> test_methodInvocation_notEdgeInsets_noLint() async {
    // visitMethodInvocation with non-EdgeInsets type — should not trigger
    await assertNoDiagnostics(r'''
class NotEdgeInsets {
  static NotEdgeInsets fromLTRB(double l, double t, double r, double b) =>
      NotEdgeInsets();
}
final p = NotEdgeInsets.fromLTRB(8, 8, 8, 8);
''');
  }

  Future<void> test_fromLTRB_onlyBottom() async {
    // Exercises _checkFromLTRB .only() suggestion with bottom only (lines 160-161)
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.fromLTRB(0, 0, 0, 8);
''',
      [lint(50, 31)],
    );
  }

  Future<void> test_fromLTRB_onlyRight() async {
    // Exercises _checkFromLTRB .only() suggestion with right only
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.fromLTRB(0, 0, 8, 0);
''',
      [lint(50, 31)],
    );
  }

  Future<void> test_fromLTRB_threeNonZero() async {
    // Exercises .only() with 3 non-zero values (nonZeroCount < 4)
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.fromLTRB(8, 4, 0, 2);
''',
      [lint(50, 31)],
    );
  }

  Future<void> test_methodInvocation_nonSimpleIdentifier_noLint() async {
    // Tests line 74: target is not SimpleIdentifier — should not trigger
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';
EdgeInsets getInsets() => EdgeInsets.all(8);
final p = getInsets();
''');
  }

  // --- Cover visitMethodInvocation EdgeInsets.only path (lines 76-77) ---

  Future<void> test_methodInvocation_only_allEqual() async {
    // EdgeInsets.only() via MethodInvocation — exercises lines 76-77
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.only(left: 8, top: 8, right: 8, bottom: 8);
''',
      [lint(50, 53)],
    );
  }

  Future<void> test_methodInvocation_symmetric_bothEqual() async {
    // EdgeInsets.symmetric() via MethodInvocation — exercises lines 76-77
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.symmetric(horizontal: 8, vertical: 8);
''',
      [lint(50, 48)],
    );
  }

  Future<void> test_methodInvocation_all_zero() async {
    // EdgeInsets.all(0) via MethodInvocation — exercises lines 76-77
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final p = EdgeInsets.all(0);
''',
      [lint(50, 17)],
    );
  }

  // --- Cover visitMethodInvocation with static factory method (lines 76-77) ---

  Future<void> test_staticMethod_fromLTRB_allEqual() async {
    // EdgeInsetsHelper.fromLTRB returns EdgeInsets via static method —
    // parsed as MethodInvocation, exercises lines 76-77
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final p = EdgeInsetsHelper.fromLTRB(8, 8, 8, 8);
''',
      [lint(50, 37)],
    );
  }

  Future<void> test_staticMethod_only_allEqual() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final p = EdgeInsetsHelper.only(left: 8, top: 8, right: 8, bottom: 8);
''',
      [lint(50, 59)],
    );
  }

  Future<void> test_staticMethod_symmetric_bothEqual() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final p = EdgeInsetsHelper.symmetric(horizontal: 8, vertical: 8);
''',
      [lint(50, 54)],
    );
  }

  Future<void> test_staticMethod_all_zero() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
final p = EdgeInsetsHelper.all(0);
''',
      [lint(50, 23)],
    );
  }
}
