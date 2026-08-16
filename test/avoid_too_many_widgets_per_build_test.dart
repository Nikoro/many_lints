import 'package:many_lints/src/rules/avoid_too_many_widgets_per_build.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidTooManyWidgetsPerBuildTest),
  );
}

@reflectiveTest
class AvoidTooManyWidgetsPerBuildTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidTooManyWidgetsPerBuild();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class BuildContext {}
class Key {}
class Widget {
  const Widget({this.key});
  final Key? key;
}
class StatelessWidget extends Widget {
  const StatelessWidget({super.key});
  Widget build(BuildContext context) => this;
}
class Column extends Widget {
  const Column({super.key, List<Widget> children = const []});
}
class Text extends Widget {
  const Text(String data, {super.key});
}
class Builder extends Widget {
  const Builder({super.key, required Widget Function(BuildContext) builder});
}
''');
    super.setUp();
  }

  /// A `build` returning a Column of [count] Texts, so the widget total is
  /// [count] + 1.
  String _buildWith(int count) {
    final children = List.generate(
      count,
      (i) => "        Text('$i'),",
    ).join('\n');

    return '''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
$children
      ],
    );
  }
}
''';
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_overTheDefaultBudget() async {
    await assertDiagnostics(_buildWith(20), [lint(134, 5)]);
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_atTheDefaultBudget() async {
    await assertNoDiagnostics(_buildWith(19));
  }

  Future<void> test_smallBuild() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) => const Text('x');
}
''');
  }

  Future<void> test_nonWidgetMethodIsNotMeasured() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class NotAWidget {
  String build(BuildContext context) => 'x';
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_builderClosureIsCountedSeparately() async {
    // 15 widgets in the method and 15 in the builder: neither alone is over
    // budget, and they must not be summed.
    final outer = List.generate(14, (i) => "        Text('$i'),").join('\n');
    final inner = List.generate(
      14,
      (i) => "            Text('$i'),",
    ).join('\n');

    await assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
$outer
        Builder(
          builder: (context) => Column(
            children: [
$inner
            ],
          ),
        ),
      ],
    );
  }
}
''');
  }

  Future<void> test_widgetReturningHelperIsAlsoMeasured() async {
    // Measured on the return type, not the name, so an extracted helper does
    // not escape the budget just by being called something else.
    final children = List.generate(20, (i) => "        Text('$i'),").join('\n');

    await assertDiagnostics(
      '''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  Widget _row() {
    return Column(
      children: [
$children
      ],
    );
  }

  @override
  Widget build(BuildContext context) => _row();
}
''',
      [lint(122, 4)],
    );
  }
}
