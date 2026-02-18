import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_unnecessary_overrides_in_state.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidUnnecessaryOverridesInStateTest),
  );
}

@reflectiveTest
class AvoidUnnecessaryOverridesInStateTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryOverridesInState();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {
  const Widget({Key? key});
}

class Key {}

class StatefulWidget extends Widget {
  const StatefulWidget({super.key});
  State createState() => State();
}

class State<T extends StatefulWidget> {
  void initState() {}
  void dispose() {}
  void didChangeDependencies() {}
  void didUpdateWidget(covariant T oldWidget) {}
  void setState(void Function() fn) {}
  Widget build(Object context) => const Widget();
  void activate() {}
  void deactivate() {}
}
''');
    super.setUp();
  }

  Future<void> test_disposeOnlySuperCall() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class _MyState extends State {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(Object context) => const Widget();
}
''',
      [lint(73, 53)],
    );
  }

  Future<void> test_initStateOnlySuperCall() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class _MyState extends State {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(Object context) => const Widget();
}
''',
      [lint(73, 57)],
    );
  }

  Future<void> test_expressionBodyOnlySuperCall() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class _MyState extends State {
  @override
  void initState() => super.initState();

  @override
  Widget build(Object context) => const Widget();
}
''',
      [lint(73, 50)],
    );
  }

  Future<void> test_disposeWithAdditionalStatements() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class _MyState extends State {
  @override
  void dispose() {
    print('cleanup');
    super.dispose();
  }

  @override
  Widget build(Object context) => const Widget();
}
''');
  }

  Future<void> test_initStateWithAdditionalStatements() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class _MyState extends State {
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _counter = 1;
  }

  @override
  Widget build(Object context) => const Widget();
}
''');
  }

  Future<void> test_notAStateClass() async {
    await assertNoDiagnostics(r'''
class MyParent {
  void dispose() {}
}

class MyClass extends MyParent {
  @override
  void dispose() {
    super.dispose();
  }
}
''');
  }

  Future<void> test_multipleUnnecessaryOverrides() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class _MyState extends State {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(Object context) => const Widget();
}
''',
      [lint(73, 57), lint(134, 53)],
    );
  }

  Future<void> test_didChangeDependenciesOnlySuperCall() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class _MyState extends State {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(Object context) => const Widget();
}
''',
      [lint(73, 81)],
    );
  }

  Future<void> test_noOverrideAnnotation() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class _MyState extends State {
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(Object context) => const Widget();
}
''');
  }

  Future<void> test_buildMethodNotFlagged() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class _MyState extends State {
  @override
  Widget build(Object context) => const Widget();
}
''');
  }

  Future<void> test_superCallWithArguments() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class _MyState extends State<StatefulWidget> {
  @override
  void didUpdateWidget(StatefulWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(Object context) => const Widget();
}
''');
  }
}
