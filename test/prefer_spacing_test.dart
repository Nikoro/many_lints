import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_spacing.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferSpacingTest));
}

@reflectiveTest
class PreferSpacingTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferSpacing();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {
  const Widget();
}
class Key {}
class Column extends Widget {
  const Column({Key? key, double? spacing, List<Widget>? children});
}
class Row extends Widget {
  const Row({Key? key, double? spacing, List<Widget>? children});
}
class Flex extends Widget {
  const Flex({Key? key, double? spacing, List<Widget>? children});
}
class SizedBox extends Widget {
  const SizedBox({Key? key, double? width, double? height, Widget? child});
}
class Container extends Widget {
  const Container({Key? key, double? width, double? height});
}
class Text extends Widget {
  const Text(String data);
}
''');
    super.setUp();
  }

  // ==============================
  // Pattern 1: Direct SizedBox in children list
  // ==============================

  Future<void> test_sizedBox_height_in_column() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [Container(height: 20), SizedBox(height: 10), Container(height: 20)]);
}
''',
      [lint(102, 20)],
    );
  }

  Future<void> test_sizedBox_width_in_row() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Row(children: [Container(width: 20), SizedBox(width: 10), Container(width: 20)]);
}
''',
      [lint(98, 19)],
    );
  }

  Future<void> test_const_sizedBox_in_column() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [Container(height: 20), const SizedBox(height: 10), Container(height: 20)]);
}
''',
      [lint(102, 26)],
    );
  }

  Future<void> test_multiple_uniform_sizedBox_in_column() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [Container(height: 20), SizedBox(height: 10), Container(height: 20), SizedBox(height: 10), Container(height: 20)]);
}
''',
      [lint(102, 20), lint(147, 20)],
    );
  }

  Future<void> test_sizedBox_in_flex() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Flex(children: [Container(height: 20), SizedBox(height: 10), Container(height: 20)]);
}
''',
      [lint(100, 20)],
    );
  }

  // ==============================
  // Pattern 1: Negative cases
  // ==============================

  Future<void> test_no_lint_when_spacing_already_set() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(spacing: 10, children: [Container(height: 20), SizedBox(height: 10), Container(height: 20)]);
}
''');
  }

  Future<void> test_no_lint_for_mixed_spacing_values() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [Container(height: 20), SizedBox(height: 10), Container(height: 20), SizedBox(height: 20), Container(height: 20)]);
}
''');
  }

  Future<void> test_no_lint_for_sizedBox_with_child() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [Container(height: 20), SizedBox(height: 10, child: Container()), Container(height: 20)]);
}
''');
  }

  Future<void> test_no_lint_for_sizedBox_with_both_dimensions() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [Container(height: 20), SizedBox(height: 10, width: 10), Container(height: 20)]);
}
''');
  }

  Future<void> test_no_lint_for_sizedBox_outside_flex() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return SizedBox(height: 20);
}
''');
  }

  Future<void> test_no_lint_for_wrong_axis_width_in_column() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [Container(height: 20), SizedBox(width: 10), Container(height: 20)]);
}
''');
  }

  Future<void> test_no_lint_for_wrong_axis_height_in_row() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Row(children: [Container(width: 20), SizedBox(height: 10), Container(width: 20)]);
}
''');
  }

  Future<void> test_no_lint_for_too_few_children() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [SizedBox(height: 10), Container(height: 20)]);
}
''');
  }

  // ==============================
  // Pattern 2: .separatedBy() with SizedBox
  // ==============================

  Future<void> test_separatedBy_with_sizedBox() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

extension ListSeparate on List<Widget> {
  List<Widget> separatedBy(Widget separator) => [];
}

Widget f() {
  return Column(children: <Widget>[Text('A'), Text('B')].separatedBy(const SizedBox(height: 10)));
}
''',
      [lint(175, 70)],
    );
  }

  Future<void> test_separatedBy_no_lint_when_spacing_set() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

extension ListSeparate on List<Widget> {
  List<Widget> separatedBy(Widget separator) => [];
}

Widget f() {
  return Column(spacing: 10, children: <Widget>[Text('A'), Text('B')].separatedBy(const SizedBox(height: 10)));
}
''');
  }

  // ==============================
  // Pattern 3: .expand() yielding SizedBox
  // ==============================

  Future<void> test_expand_with_sizedBox_yield() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  final List<Widget> widgets = [Text('A'), Text('B')];
  return Column(children: widgets.expand((widget) sync* { yield const SizedBox(height: 10); yield widget; }).toList());
}
''',
      [lint(133, 82)],
    );
  }

  Future<void> test_expand_no_lint_when_spacing_set() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  final List<Widget> widgets = [Text('A'), Text('B')];
  return Column(spacing: 10, children: widgets.expand((widget) sync* { yield const SizedBox(height: 10); yield widget; }).toList());
}
''');
  }

  // ==============================
  // Edge cases
  // ==============================

  Future<void> test_sizedBox_any_axis_in_flex() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Flex(children: [Container(width: 20), SizedBox(width: 10), Container(width: 20)]);
}
''',
      [lint(99, 19)],
    );
  }
}
