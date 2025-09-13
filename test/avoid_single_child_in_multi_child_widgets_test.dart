import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_single_child_in_multi_child_widgets.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
      () => defineReflectiveTests(AvoidSingleChildInMultiChildWidgetsTest));
}

@reflectiveTest
class AvoidSingleChildInMultiChildWidgetsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidSingleChildInMultiChildWidgets();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {}
class Key {}
class Column extends Widget {
  Column({Key? key, List<Widget>? children});
}
class Row extends Widget {
  Row({Key? key, List<Widget>? children});
}
class Wrap extends Widget {
  Wrap({Key? key, List<Widget>? children});
}
class Flex extends Widget {
  Flex({Key? key, List<Widget>? children});
}
class SliverList extends Widget {
  SliverList({Key? key, List<Widget>? children});
}
class Container extends Widget {}
class Text extends Widget {
  Text(String data);
}
''');
    super.setUp();
  }

  Future<void> test_columnWithSingleChild() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [Text('hello')]);
}
''',
      [lint(61, 6)],
    );
  }

  Future<void> test_rowWithSingleChild() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Row(children: [Text('hello')]);
}
''',
      [lint(61, 3)],
    );
  }

  Future<void> test_columnWithMultipleChildren() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [Text('hello'), Text('world')]);
}
''');
  }

  Future<void> test_columnWithEmptyChildren() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: []);
}
''');
  }

  Future<void> test_columnWithSpreadElement() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f(List<Widget> widgets) {
  return Column(children: [...widgets]);
}
''');
  }

  Future<void> test_columnWithForElement() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [for (var i = 0; i < 3; i++) Text('$i')]);
}
''');
  }

  Future<void> test_wrapWithSingleChild() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Wrap(children: [Text('hello')]);
}
''',
      [lint(61, 4)],
    );
  }
}
