import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/use_gap.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(UseGapTest));
}

@reflectiveTest
class UseGapTest extends ManyLintsRuleTest {
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

  Future<void> test_sized_box_height_in_column() async {
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

  Future<void> test_sized_box_width_in_row() async {
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

  Future<void> test_const_sized_box_in_column() async {
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

  Future<void> test_sized_box_in_wrap() async {
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

  Future<void> test_sized_box_in_list_view() async {
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

  Future<void> test_sized_box_with_both_dimensions() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [SizedBox(height: 20, width: 20)]);
}
''');
  }

  Future<void> test_sized_box_with_child() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [SizedBox(height: 20, child: Container())]);
}
''');
  }

  Future<void> test_sized_box_outside_multi_child() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return SizedBox(height: 20);
}
''');
  }

  Future<void> test_sized_box_width_in_column() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [SizedBox(width: 20)]);
}
''');
  }

  Future<void> test_sized_box_height_in_row() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Row(children: [SizedBox(height: 20)]);
}
''');
  }

  // === Padding cases ===

  Future<void> test_padding_bottom_in_column() async {
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

  Future<void> test_padding_top_in_column() async {
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

  Future<void> test_padding_right_in_row() async {
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

  Future<void> test_padding_all_in_column() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [Padding(padding: EdgeInsets.all(20), child: Container())]);
}
''');
  }

  Future<void> test_padding_left_in_column() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [Padding(padding: EdgeInsets.only(left: 20), child: Container())]);
}
''');
  }

  Future<void> test_padding_multiple_directions() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [Padding(padding: EdgeInsets.only(top: 20, bottom: 10), child: Container())]);
}
''');
  }

  Future<void> test_padding_outside_multi_child() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Padding(padding: EdgeInsets.only(bottom: 20), child: Container());
}
''');
  }

  // === Gap is ok ===

  Future<void> test_gap_in_column() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';
Widget f() {
  return Column(children: [Container(height: 20), Gap(20), Container(height: 20)]);
}
''');
  }
}
