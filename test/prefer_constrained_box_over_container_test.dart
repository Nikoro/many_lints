import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_constrained_box_over_container.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferConstrainedBoxOverContainerTest),
  );
}

@reflectiveTest
class PreferConstrainedBoxOverContainerTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferConstrainedBoxOverContainer();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {}
class Key {}
class BoxConstraints {
  const BoxConstraints({double? minWidth, double? maxWidth, double? minHeight, double? maxHeight});
  const BoxConstraints.tightFor({double? width, double? height});
}
class EdgeInsets {
  const EdgeInsets.all(double value);
}
class Container extends Widget {
  Container({Key? key, BoxConstraints? constraints, EdgeInsets? padding, EdgeInsets? margin, Widget? child, double? width, double? height});
}
class ConstrainedBox extends Widget {
  ConstrainedBox({Key? key, required BoxConstraints constraints, Widget? child});
}
''');
    super.setUp();
  }

  Future<void> test_containerWithOnlyConstraints() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(constraints: BoxConstraints());
}
''',
      [lint(61, 9)],
    );
  }

  Future<void> test_containerWithConstraintsAndChild() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(constraints: BoxConstraints(), child: Container());
}
''',
      [lint(61, 9)],
    );
  }

  Future<void> test_containerWithConstraintsAndKey() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(key: Key(), constraints: BoxConstraints());
}
''',
      [lint(61, 9)],
    );
  }

  Future<void> test_containerWithConstraintsAndPadding() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(constraints: BoxConstraints(), padding: EdgeInsets.all(8));
}
''');
  }

  Future<void> test_containerWithConstraintsAndWidth() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(constraints: BoxConstraints(), width: 100);
}
''');
  }

  Future<void> test_containerWithoutConstraints() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(width: 100);
}
''');
  }

  Future<void> test_containerWithConstraintsTightFor() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(constraints: BoxConstraints.tightFor(width: 100));
}
''',
      [lint(61, 9)],
    );
  }
}
