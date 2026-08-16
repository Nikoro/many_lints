import 'package:many_lints/src/rules/avoid_deep_widget_nesting.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidDeepWidgetNestingTest),
  );
}

@reflectiveTest
class AvoidDeepWidgetNestingTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidDeepWidgetNesting();
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
class Padding extends Widget {
  const Padding({super.key, Widget? child});
}
class Center extends Widget {
  const Center({super.key, Widget? child});
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

  /// A chain of [depth] nested `Padding` widgets around a `Text`.
  String _nested(int depth) {
    final open = List.generate(depth, (_) => 'Padding(child: ').join();
    final close = List.generate(depth, (_) => ')').join();

    return '''
import 'package:flutter/widgets.dart';

Widget build() => ${open}Text('x')$close;
''';
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_overTheDefaultBudget() async {
    // 8 Paddings + the Text at the bottom is a depth of 9.
    await assertDiagnostics(_nested(8), [lint(58, 137)]);
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_atTheDefaultBudget() async {
    await assertNoDiagnostics(_nested(7));
  }

  Future<void> test_shallowTree() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() => Center(child: Padding(child: Text('x')));
''');
  }

  Future<void> test_nonWidgetNestingIsNotCounted() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() => Column(
      children: [
        for (var i = 0; i < 3; i++)
          if (i > 0) Padding(child: Text('x')) else Text('y'),
      ],
    );
''');
  }

  // ---- Edge cases ----

  Future<void> test_builderClosureStartsANewTree() async {
    // Four levels outside plus four inside the closure is not eight: the
    // builder builds its own subtree.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() => Padding(
      child: Padding(
        child: Padding(
          child: Builder(
            builder: (context) => Padding(
              child: Padding(
                child: Padding(child: Text('x')),
              ),
            ),
          ),
        ),
      ),
    );
''');
  }

  // The anchor is the shallowest widget past the limit, not the deepest one:
  // it is the node worth extracting, and it makes a long chain report once
  // instead of at every level past the budget.
  Future<void> test_onlyOneDiagnosticPerOverNestedPath() async {
    await assertDiagnostics(_nested(9), [lint(58, 153)]);
  }

  // Two sibling leaves at the same depth — the arms of a ternary, the
  // children of a Row — share the one path that is too deep, so they report
  // once between them rather than once each. This came from a production run
  // where a ternary produced two diagnostics for one fix.
  Future<void> test_siblingLeavesReportOnce() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Widget build(bool flag) => Padding(
      child: Padding(
        child: Padding(
          child: Padding(
            child: Padding(
              child: Padding(
                child: Padding(
                  child: Padding(
                    child: flag ? Text('a') : Text('b'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
''',
      [lint(67, 372)],
    );
  }
}
