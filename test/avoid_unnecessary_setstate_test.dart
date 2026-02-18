import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_unnecessary_setstate.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidUnnecessarySetstateTest),
  );
}

@reflectiveTest
class AvoidUnnecessarySetstateTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessarySetstate();

    final flutter = newPackage('flutter');
    flutter.addFile('lib/widgets.dart', r'''
class BuildContext {
  bool get mounted => true;
}

class Widget {
  const Widget({Key? key});
}

class Key {}

class StatelessWidget extends Widget {}
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
  void didUpdateWidget(covariant T oldWidget) {}
  Widget build(BuildContext context);
}

class ElevatedButton extends Widget {
  const ElevatedButton({
    super.key,
    void Function()? onPressed,
    void Function()? onLongPress,
    required Widget child,
  });
}

class Text extends Widget {
  const Text(String data, {super.key});
}

class SizedBox extends Widget {
  const SizedBox({super.key});
}
''');

    super.setUp();
  }

  // --- Positive cases: should trigger lint ---

  Future<void> test_setStateInInitState() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  String _data = '';

  @override
  void initState() {
    super.initState();
    setState(() {
      _data = 'Hello';
    });
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      [lint(277, 43)],
    );
  }

  Future<void> test_setStateInInitStateWithCondition() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  String _data = '';
  bool condition = true;

  @override
  void initState() {
    super.initState();
    if (condition) {
      setState(() {
        _data = 'Hello';
      });
    }
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      [lint(325, 47)],
    );
  }

  Future<void> test_setStateInDidUpdateWidget() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  String _data = '';

  @override
  void didUpdateWidget(MyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      _data = 'Hello';
    });
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      [lint(316, 43)],
    );
  }

  Future<void> test_setStateInBuild() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  String _data = '';

  @override
  Widget build(BuildContext context) {
    setState(() {
      _data = 'Hello';
    });
    return const Widget();
  }
}
''',
      [lint(272, 43)],
    );
  }

  Future<void> test_setStateInBuildWithCondition() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  String _data = '';
  bool condition = true;

  @override
  Widget build(BuildContext context) {
    if (condition) {
      setState(() {
        _data = 'Hello';
      });
    }
    return const Widget();
  }
}
''',
      [lint(320, 47)],
    );
  }

  Future<void> test_multipleSetStateInInitState() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  String _a = '';
  String _b = '';

  @override
  void initState() {
    super.initState();
    setState(() {
      _a = 'Hello';
    });
    setState(() {
      _b = 'World';
    });
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      [lint(292, 40), lint(338, 40)],
    );
  }

  // --- Negative cases: should NOT trigger lint ---

  Future<void> test_setStateInCustomMethod() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  String _data = '';

  void _update() {
    setState(() {
      _data = 'Hello';
    });
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }

  Future<void> test_setStateInAsyncMethod() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  String _data = '';

  Future<void> _loadData() async {
    _data = await Future.value('Hello');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }

  Future<void> test_setStateInOnPressedCallback() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  String _data = '';

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _data = 'Hello';
        });
      },
      child: const Text('Press'),
    );
  }
}
''');
  }

  Future<void> test_setStateInOnLongPressCallback() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  String _data = '';

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onLongPress: () {
        setState(() {
          _data = 'Hello';
        });
      },
      onPressed: () {},
      child: const Text('Press'),
    );
  }
}
''');
  }

  Future<void> test_notAStateClass() async {
    await assertNoDiagnostics(r'''
class NotAState {
  void setState(void Function() fn) {
    fn();
  }

  void initState() {
    setState(() {});
  }
}
''');
  }

  Future<void> test_directStateAssignmentInInitState() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  String _data = '';

  @override
  void initState() {
    super.initState();
    _data = 'Hello';
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }

  Future<void> test_setStateInDispose() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void dispose() {
    setState(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }
}
