import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_state_constructors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidStateConstructorsTest),
  );
}

@reflectiveTest
class AvoidStateConstructorsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidStateConstructors();

    final flutter = newPackage('flutter');
    flutter.addFile('lib/widgets.dart', r'''
class BuildContext {}

class Widget {
  const Widget({Key? key});
}

class Key {}

class StatefulWidget extends Widget {
  const StatefulWidget({super.key});
  State createState() => throw UnimplementedError();
}

abstract class State<T extends StatefulWidget> {
  BuildContext get context => BuildContext();
  bool get mounted => true;
  void setState(void Function() fn) {}
  void initState() {}
  void dispose() {}
  Widget build(BuildContext context);
}
''');

    super.setUp();
  }

  // --- Positive cases: should trigger lint ---

  Future<void> test_constructorWithBody() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late String _data;

  _MyWidgetState() {
    _data = 'Hello';
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      [lint(219, 43)],
    );
  }

  Future<void> test_constructorWithInitializerList() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final String _data;

  _MyWidgetState() : _data = 'Hello';

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      [lint(220, 35)],
    );
  }

  Future<void> test_constructorWithMultipleInitializers() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final String _a;
  final int _b;

  _MyWidgetState() : _a = 'x', _b = 0;

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      [lint(233, 36)],
    );
  }

  Future<void> test_constructorWithBodyAndInitializers() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final String _a;
  late int _b;

  _MyWidgetState() : _a = 'x' {
    _b = 42;
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      [lint(232, 46)],
    );
  }

  Future<void> test_namedConstructorWithBody() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState.custom();
}

class _MyWidgetState extends State<MyWidget> {
  late String _data;

  _MyWidgetState.custom() {
    _data = 'custom';
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      [lint(226, 51)],
    );
  }

  // --- Negative cases: should NOT trigger lint ---

  Future<void> test_noConstructor() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }

  Future<void> test_emptyConstructor() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  _MyWidgetState();

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }

  Future<void> test_constructorWithEmptyBody() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  _MyWidgetState() {}

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }

  Future<void> test_notAStateClass() async {
    await assertNoDiagnostics(r'''
class NotAState {
  late String _data;

  NotAState() {
    _data = 'Hello';
  }
}
''');
  }

  Future<void> test_constructorWithSuperOnly() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  _MyWidgetState() : super();

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }
}
