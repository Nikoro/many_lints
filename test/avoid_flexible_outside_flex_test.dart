import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_flexible_outside_flex.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidFlexibleOutsideFlexTest),
  );
}

@reflectiveTest
class AvoidFlexibleOutsideFlexTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidFlexibleOutsideFlex();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {
  const Widget();
}
class Key {}
class Flex extends Widget {
  const Flex({Key? key, required int direction, List<Widget>? children});
}
class Row extends Flex {
  const Row({Key? key, List<Widget>? children});
}
class Column extends Flex {
  const Column({Key? key, List<Widget>? children});
}
class Flexible extends Widget {
  const Flexible({Key? key, int flex = 1, Widget? child});
}
class Expanded extends Flexible {
  const Expanded({Key? key, Widget? child});
}
class Container extends Widget {
  const Container({Key? key, Widget? child});
}
class SizedBox extends Widget {
  const SizedBox({Key? key, Widget? child});
}
class Center extends Widget {
  const Center({Key? key, Widget? child});
}
class Text extends Widget {
  const Text(String data);
}
class Padding extends Widget {
  const Padding({Key? key, required Object padding, Widget? child});
}
class Stack extends Widget {
  const Stack({Key? key, List<Widget>? children});
}
''');
    super.setUp();
  }

  // --- Cases that SHOULD trigger the lint ---

  Future<void> test_expandedInsideContainer() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(child: Expanded(child: Text('hello')));
}
''',
      [lint(78, 8)],
    );
  }

  Future<void> test_flexibleInsideContainer() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(child: Flexible(child: Text('hello')));
}
''',
      [lint(78, 8)],
    );
  }

  Future<void> test_expandedInsideSizedBox() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return SizedBox(child: Expanded(child: Text('hello')));
}
''',
      [lint(77, 8)],
    );
  }

  Future<void> test_expandedInsideCenter() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Center(child: Expanded(child: Text('hello')));
}
''',
      [lint(75, 8)],
    );
  }

  Future<void> test_flexibleInsideStackChildren() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Stack(children: [Flexible(child: Text('hello'))]);
}
''',
      [lint(78, 8)],
    );
  }

  Future<void> test_expandedInsidePadding() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Padding(padding: Object(), child: Expanded(child: Text('hello')));
}
''',
      [lint(95, 8)],
    );
  }

  Future<void> test_expandedAtTopLevelReturn() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Expanded(child: Text('hello'));
}
''',
      [lint(61, 8)],
    );
  }

  // --- Cases that should NOT trigger the lint ---

  Future<void> test_expandedDirectChildOfRow() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Row(children: [Expanded(child: Text('hello'))]);
}
''');
  }

  Future<void> test_expandedDirectChildOfColumn() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [Expanded(child: Text('hello'))]);
}
''');
  }

  Future<void> test_flexibleDirectChildOfRow() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Row(children: [Flexible(child: Text('hello'))]);
}
''');
  }

  Future<void> test_flexibleDirectChildOfColumn() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [Flexible(child: Text('hello'))]);
}
''');
  }

  Future<void> test_expandedDirectChildOfFlex() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Flex(direction: 0, children: [Expanded(child: Text('hello'))]);
}
''');
  }

  Future<void> test_multipleExpandedInRow() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Row(children: [
    Expanded(child: Text('a')),
    Expanded(child: Text('b')),
  ]);
}
''');
  }

  Future<void> test_expandedAsPositionalArgOfRow() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [Expanded(child: Text('hello'))]);
}
''');
  }
}
