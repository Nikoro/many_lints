import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/avoid_recursive_widget_calls.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidRecursiveWidgetCallsTest),
  );
}

@reflectiveTest
class AvoidRecursiveWidgetCallsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidRecursiveWidgetCalls();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {
  const Widget();
}
class BuildContext {}
class StatelessWidget extends Widget {
  const StatelessWidget();
  Widget build(BuildContext context) => const Widget();
}
class StatefulWidget extends Widget {
  const StatefulWidget();
}
class State<T extends StatefulWidget> {
  Widget build(BuildContext context) => Widget();
}
class Text extends Widget {
  Text(this.data);
  final String data;
}
class SizedBox extends Widget {
  const SizedBox();
}
class Column extends Widget {
  Column({this.children = const []});
  final List<Widget> children;
}
class Builder extends Widget {
  Builder({required this.builder});
  final Widget Function(BuildContext) builder;
}
''');
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_statelessWidgetBuildsItself() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MyWidget();
  }
}
''',
      [lint(143, 10)],
    );
  }

  Future<void> test_statelessWidgetBuildsItselfNested() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [MyWidget()]);
  }
}
''',
      [lint(161, 10)],
    );
  }

  Future<void> test_stateBuildsItsWidget() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {}

class MyState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return MyWidget();
  }
}
''',
      [lint(184, 10)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_buildsDifferentWidget() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
''');
  }

  Future<void> test_recursionGuardedByIf() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  const MyWidget(this.depth);
  final int depth;

  @override
  Widget build(BuildContext context) {
    if (depth > 0) {
      return MyWidget(depth - 1);
    }
    return const SizedBox();
  }
}
''');
  }

  Future<void> test_recursionGuardedByTernary() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  const MyWidget(this.depth);
  final int depth;

  @override
  Widget build(BuildContext context) {
    return depth > 0 ? MyWidget(depth - 1) : const SizedBox();
  }
}
''');
  }

  Future<void> test_selfInsideBuilderCallback() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) => MyWidget());
  }
}
''');
  }

  Future<void> test_selfConstructionOutsideBuild() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  Widget makeAnother() => MyWidget();

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
''');
  }

  Future<void> test_nonWidgetClassSelfConstruction() async {
    await assertNoDiagnostics(r'''
class NotAWidget {
  NotAWidget build() {
    return NotAWidget();
  }
}
''');
  }

  Future<void> test_differentWidgetOfSameFamily() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class OtherWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OtherWidget();
  }
}
''');
  }
}
