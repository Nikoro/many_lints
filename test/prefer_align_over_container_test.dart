import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/prefer_align_over_container.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferAlignOverContainerTest),
  );
}

@reflectiveTest
class PreferAlignOverContainerTest extends ManyLintsRuleTest {
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

  Future<void> test_container_with_only_alignment() async {
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

  Future<void> test_container_with_alignment_and_child() async {
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

  Future<void> test_container_with_alignment_and_key() async {
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

  Future<void> test_container_with_multiple_params() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(alignment: Alignment.center, width: 100);
}
''');
  }

  Future<void> test_container_with_no_alignment() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(width: 100);
}
''');
  }
}
