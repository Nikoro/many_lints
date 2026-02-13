import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_single_child_in_multi_child_widgets.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidSingleChildInMultiChildWidgetsTest),
  );
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

  Future<void> test_column_with_single_child() async {
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

  Future<void> test_row_with_single_child() async {
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

  Future<void> test_column_with_multiple_children() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [Text('hello'), Text('world')]);
}
''');
  }

  Future<void> test_column_with_empty_children() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: []);
}
''');
  }

  Future<void> test_column_with_spread_element() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f(List<Widget> widgets) {
  return Column(children: [...widgets]);
}
''');
  }

  Future<void> test_column_with_for_element() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Column(children: [for (var i = 0; i < 3; i++) Text('$i')]);
}
''');
  }

  Future<void> test_wrap_with_single_child() async {
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

  Future<void> test_column_with_if_element_with_else() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f(bool condition) {
  return Column(children: [
    if (condition) Text('true') else Text('false'),
  ]);
}
''',
      [lint(75, 6)],
    );
  }

  Future<void> test_column_with_if_element_without_else() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f(bool condition) {
  return Column(children: [
    if (condition) Text('hello'),
  ]);
}
''',
      [lint(75, 6)],
    );
  }

  Future<void> test_sliver_child_list_delegate_with_single_child() async {
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
class SliverChildListDelegate {
  SliverChildListDelegate(List<Widget> children);
}
class Container extends Widget {}
class Text extends Widget {
  Text(String data);
}
''');
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
void f() {
  SliverChildListDelegate([Text('hello')]);
}
''',
      [lint(52, 23)],
    );
  }
}
