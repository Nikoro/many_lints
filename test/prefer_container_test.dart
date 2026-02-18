import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_container.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferContainerTest));
}

@reflectiveTest
class PreferContainerTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferContainer();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {}
class Key {}
class EdgeInsets {
  const EdgeInsets.all(double value);
  const EdgeInsets.symmetric({double? horizontal, double? vertical});
}
class Alignment {
  static const Alignment center = Alignment();
  static const Alignment topLeft = Alignment();
  const Alignment();
}
class BoxConstraints {
  const BoxConstraints({double? minWidth, double? maxWidth, double? minHeight, double? maxHeight});
}
class BoxDecoration {
  const BoxDecoration({dynamic color, dynamic border});
}
class Matrix4 {
  Matrix4();
  factory Matrix4.identity() = Matrix4;
}
class Container extends Widget {
  Container({Key? key, EdgeInsets? padding, EdgeInsets? margin, Alignment? alignment, dynamic color, BoxDecoration? decoration, BoxConstraints? constraints, double? width, double? height, Matrix4? transform, Widget? child});
}
class Padding extends Widget {
  Padding({Key? key, required EdgeInsets padding, Widget? child});
}
class Align extends Widget {
  Align({Key? key, Alignment? alignment, Widget? child});
}
class Center extends Widget {
  Center({Key? key, Widget? child});
}
class ColoredBox extends Widget {
  ColoredBox({Key? key, required dynamic color, Widget? child});
}
class DecoratedBox extends Widget {
  DecoratedBox({Key? key, required BoxDecoration decoration, Widget? child});
}
class ConstrainedBox extends Widget {
  ConstrainedBox({Key? key, required BoxConstraints constraints, Widget? child});
}
class SizedBox extends Widget {
  SizedBox({Key? key, double? width, double? height, Widget? child});
}
class Transform extends Widget {
  Transform({Key? key, required Matrix4 transform, Widget? child});
}
class ClipRRect extends Widget {
  ClipRRect({Key? key, Widget? child});
}
class Opacity extends Widget {
  Opacity({Key? key, required double opacity, Widget? child});
}
class Text extends Widget {
  Text(String data);
}
''');
    super.setUp();
  }

  // === Tests that SHOULD trigger the lint ===

  Future<void> test_paddingAlignSizedBox() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Padding(
    padding: EdgeInsets.all(8),
    child: Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: 100,
        height: 50,
        child: Text('Hello'),
      ),
    ),
  );
}
''',
      [lint(61, 7)],
    );
  }

  Future<void> test_paddingAlignCenterConflicts() async {
    // Align and Center both map to 'alignment', so this should NOT trigger.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Padding(
    padding: EdgeInsets.all(8),
    child: Align(
      alignment: Alignment.topLeft,
      child: Center(
        child: Text('Hello'),
      ),
    ),
  );
}
''');
  }

  Future<void> test_paddingDecoratedBoxSizedBox() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Padding(
    padding: EdgeInsets.all(8),
    child: DecoratedBox(
      decoration: BoxDecoration(),
      child: SizedBox(
        width: 100,
        child: Text('Hello'),
      ),
    ),
  );
}
''',
      [lint(61, 7)],
    );
  }

  Future<void> test_transformPaddingAlign() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Transform(
    transform: Matrix4(),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.center,
        child: Text('Hello'),
      ),
    ),
  );
}
''',
      [lint(61, 9)],
    );
  }

  Future<void> test_paddingColoredBoxConstrainedBox() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Padding(
    padding: EdgeInsets.all(8),
    child: ColoredBox(
      color: 0xFF000000,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 100),
        child: Text('Hello'),
      ),
    ),
  );
}
''',
      [lint(61, 7)],
    );
  }

  Future<void> test_fourWidgetSequence() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Padding(
    padding: EdgeInsets.all(8),
    child: Align(
      alignment: Alignment.center,
      child: ColoredBox(
        color: 0xFF000000,
        child: SizedBox(
          width: 100,
          child: Text('Hello'),
        ),
      ),
    ),
  );
}
''',
      [lint(61, 7)],
    );
  }

  // === Tests that should NOT trigger the lint ===

  Future<void> test_twoWidgetsOnly() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Padding(
    padding: EdgeInsets.all(8),
    child: Align(
      alignment: Alignment.center,
      child: Text('Hello'),
    ),
  );
}
''');
  }

  Future<void> test_singleWidget() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Padding(
    padding: EdgeInsets.all(8),
    child: Text('Hello'),
  );
}
''');
  }

  Future<void> test_containerNotTriggered() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(
    padding: EdgeInsets.all(8),
    alignment: Alignment.center,
    child: Text('Hello'),
  );
}
''');
  }

  Future<void> test_conflictingParametersTwoPaddings() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Padding(
    padding: EdgeInsets.all(8),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.center,
        child: Text('Hello'),
      ),
    ),
  );
}
''');
  }

  Future<void> test_nonContainerCompatibleWidgetBreaksChain() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Padding(
    padding: EdgeInsets.all(8),
    child: Container(
      width: 100,
      child: Align(
        alignment: Alignment.center,
        child: Text('Hello'),
      ),
    ),
  );
}
''');
  }

  Future<void> test_noChildArgument() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return SizedBox(width: 100, height: 50);
}
''');
  }

  // Edge case: only the outermost widget in the chain reports

  Future<void> test_onlyOutermostReports() async {
    // A chain of 4 widgets: only the outermost should report,
    // not the inner 3-widget subsequence.
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Padding(
    padding: EdgeInsets.all(8),
    child: Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: 100,
        child: ColoredBox(
          color: 0xFF000000,
          child: Text('Hello'),
        ),
      ),
    ),
  );
}
''',
      [lint(61, 7)],
    );
  }
}
