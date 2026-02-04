import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/use_gap.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(UseGapTest));
}

@reflectiveTest
class UseGapTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = UseGap();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {
  const Widget();
}
class Key {}
class Column extends Widget {
  const Column({Key? key, List<Widget>? children});
}
class Row extends Widget {
  const Row({Key? key, List<Widget>? children});
}
class Wrap extends Widget {
  const Wrap({Key? key, List<Widget>? children});
}
class Flex extends Widget {
  const Flex({Key? key, List<Widget>? children});
}
class ListView extends Widget {
  const ListView({Key? key, List<Widget>? children});
}
class SizedBox extends Widget {
  const SizedBox({Key? key, double? width, double? height, Widget? child});
}
class Container extends Widget {
  const Container({Key? key, double? width, double? height});
}
class Padding extends Widget {
  const Padding({Key? key, required EdgeInsetsGeometry padding, Widget? child});
}
class EdgeInsetsGeometry {
  const EdgeInsetsGeometry();
}
class EdgeInsets extends EdgeInsetsGeometry {
  const EdgeInsets.only({double left = 0, double top = 0, double right = 0, double bottom = 0});
  const EdgeInsets.all(double value);
  const EdgeInsets.symmetric({double vertical = 0, double horizontal = 0});
}
class Text extends Widget {
  const Text(String data);
}
''');
    newPackage('gap').addFile('lib/gap.dart', r'''
import 'package:flutter/widgets.dart';
class Gap extends Widget {
  const Gap(double size);
}
''');
    super.setUp();
  }

  // === SizedBox cases ===

  Future<void> test_sizedBoxHeightInColumn() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [Container(height: 20), SizedBox(height: 20), Container(height: 20)]);
}
''',
      [lint(102, 8)],
    );
  }

  Future<void> test_sizedBoxWidthInRow() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Row(children: [Container(width: 20), SizedBox(width: 20), Container(width: 20)]);
}
''',
      [lint(98, 8)],
    );
  }

  Future<void> test_constSizedBoxInColumn() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [Container(height: 20), const SizedBox(height: 20), Container(height: 20)]);
}
''',
      [lint(108, 8)],
    );
  }

  Future<void> test_sizedBoxInWrap() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Wrap(children: [Container(height: 20), SizedBox(height: 20), Container(height: 20)]);
}
''',
      [lint(100, 8)],
    );
  }

  Future<void> test_sizedBoxInListView() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return ListView(children: [Container(height: 20), SizedBox(height: 20), Container(height: 20)]);
}
''',
      [lint(104, 8)],
    );
  }

  // === SizedBox negative cases ===

  Future<void> test_sizedBoxWithBothDimensions() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [SizedBox(height: 20, width: 20)]);
}
''');
  }

  Future<void> test_sizedBoxWithChild() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [SizedBox(height: 20, child: Container())]);
}
''');
  }

  Future<void> test_sizedBoxOutsideMultiChild() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return SizedBox(height: 20);
}
''');
  }

  Future<void> test_sizedBoxWidthInColumn() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [SizedBox(width: 20)]);
}
''');
  }

  Future<void> test_sizedBoxHeightInRow() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Row(children: [SizedBox(height: 20)]);
}
''');
  }

  // === Padding cases ===

  Future<void> test_paddingBottomInColumn() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [Padding(padding: EdgeInsets.only(bottom: 20), child: Container()), Container(height: 20)]);
}
''',
      [lint(79, 7)],
    );
  }

  Future<void> test_paddingTopInColumn() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [Padding(padding: EdgeInsets.only(top: 20), child: Container()), Container(height: 20)]);
}
''',
      [lint(79, 7)],
    );
  }

  Future<void> test_paddingRightInRow() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Row(children: [Padding(padding: EdgeInsets.only(right: 20), child: Container()), Container(width: 20)]);
}
''',
      [lint(76, 7)],
    );
  }

  // === Padding negative cases ===

  Future<void> test_paddingAllInColumn() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [Padding(padding: EdgeInsets.all(20), child: Container())]);
}
''');
  }

  Future<void> test_paddingLeftInColumn() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [Padding(padding: EdgeInsets.only(left: 20), child: Container())]);
}
''');
  }

  Future<void> test_paddingMultipleDirections() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [Padding(padding: EdgeInsets.only(top: 20, bottom: 10), child: Container())]);
}
''');
  }

  Future<void> test_paddingOutsideMultiChild() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Padding(padding: EdgeInsets.only(bottom: 20), child: Container());
}
''');
  }

  // === Gap is ok ===

  Future<void> test_gapInColumn() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';
Widget f() {
  return Column(children: [Container(height: 20), Gap(20), Container(height: 20)]);
}
''');
  }
}
