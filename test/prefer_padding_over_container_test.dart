import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_padding_over_container.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferPaddingOverContainerTest),
  );
}

@reflectiveTest
class PreferPaddingOverContainerTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferPaddingOverContainer();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {}
class Key {}
class EdgeInsets {
  static const EdgeInsets zero = EdgeInsets.all(0);
  const EdgeInsets.all(double value);
}
class Container extends Widget {
  Container({Key? key, EdgeInsets? padding, EdgeInsets? margin, Widget? child, double? width, double? height});
}
class Padding extends Widget {
  Padding({Key? key, required EdgeInsets padding, Widget? child});
}
''');
    super.setUp();
  }

  Future<void> test_container_with_only_margin() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(margin: EdgeInsets.all(8));
}
''',
      [lint(61, 9)],
    );
  }

  Future<void> test_container_with_margin_and_child() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(margin: EdgeInsets.all(8), child: Container());
}
''',
      [lint(61, 9)],
    );
  }

  Future<void> test_container_with_margin_and_key() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(key: Key(), margin: EdgeInsets.all(8));
}
''',
      [lint(61, 9)],
    );
  }

  Future<void> test_container_with_multiple_params() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(margin: EdgeInsets.all(8), width: 100);
}
''');
  }

  Future<void> test_container_with_no_margin() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(width: 100);
}
''');
  }

  Future<void> test_container_with_only_padding() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(padding: EdgeInsets.all(8));
}
''',
      [lint(61, 9)],
    );
  }

  Future<void> test_container_with_padding_and_child() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(padding: EdgeInsets.all(8), child: Container());
}
''',
      [lint(61, 9)],
    );
  }

  Future<void> test_container_with_padding_and_key() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(key: Key(), padding: EdgeInsets.all(8));
}
''',
      [lint(61, 9)],
    );
  }

  Future<void> test_container_with_padding_and_width() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(padding: EdgeInsets.all(8), width: 100);
}
''');
  }

  Future<void> test_container_with_padding_and_margin() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(padding: EdgeInsets.all(8), margin: EdgeInsets.all(8));
}
''');
  }
}
