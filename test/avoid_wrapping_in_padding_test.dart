import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_wrapping_in_padding.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidWrappingInPaddingTest),
  );
}

@reflectiveTest
class AvoidWrappingInPaddingTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidWrappingInPadding();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {}
class Key {}
class EdgeInsets {
  static const EdgeInsets zero = EdgeInsets.all(0);
  const EdgeInsets.all(double value);
  const EdgeInsets.symmetric({double vertical = 0, double horizontal = 0});
}
class Padding extends Widget {
  Padding({Key? key, required EdgeInsets padding, Widget? child});
}
class Container extends Widget {
  Container({Key? key, EdgeInsets? padding, EdgeInsets? margin, Widget? child, double? width, double? height});
}
class Card extends Widget {
  Card({Key? key, EdgeInsets? padding, Widget? child});
}
class Text extends Widget {
  Text(String data);
}
class Icon extends Widget {
  Icon(String icon);
}
class SizedBox extends Widget {
  SizedBox({Key? key, double? width, double? height, Widget? child});
}
''');
    super.setUp();
  }

  Future<void> test_paddingWrappingContainer() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Padding(
    padding: EdgeInsets.all(8),
    child: Container(),
  );
}
''',
      [lint(61, 7)],
    );
  }

  Future<void> test_paddingWrappingContainerWithChild() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Padding(
    padding: EdgeInsets.all(8),
    child: Container(child: Text('Hello')),
  );
}
''',
      [lint(61, 7)],
    );
  }

  Future<void> test_paddingWrappingCard() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Padding(
    padding: EdgeInsets.all(8),
    child: Card(),
  );
}
''',
      [lint(61, 7)],
    );
  }

  Future<void> test_paddingWrappingContainerWithKey() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Padding(
    key: Key(),
    padding: EdgeInsets.all(8),
    child: Container(),
  );
}
''',
      [lint(61, 7)],
    );
  }

  Future<void> test_noPaddingWrappingText() async {
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

  Future<void> test_noPaddingWrappingSizedBox() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Padding(
    padding: EdgeInsets.all(8),
    child: SizedBox(width: 100),
  );
}
''');
  }

  Future<void> test_containerAlreadyHasPadding() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Padding(
    padding: EdgeInsets.all(8),
    child: Container(padding: EdgeInsets.all(4)),
  );
}
''');
  }

  Future<void> test_paddingWithoutChild() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Padding(
    padding: EdgeInsets.all(8),
  );
}
''');
  }

  Future<void> test_containerNotWrappedInPadding() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(padding: EdgeInsets.all(8));
}
''');
  }
}
