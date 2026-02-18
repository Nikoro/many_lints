import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_mounted_in_setstate.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidMountedInSetstateTest),
  );
}

@reflectiveTest
class AvoidMountedInSetstateTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidMountedInSetstate();

    final flutter = newPackage('flutter');
    flutter.addFile('lib/widgets.dart', r'''
class BuildContext {
  bool get mounted => true;
}

class Widget {}
class StatelessWidget extends Widget {}
class StatefulWidget extends Widget {
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

  Future<void> test_bareMountedInSetState() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
    setState(() {
      if (mounted) {
        // do something
      }
    });
  }

  @override
  Widget build(BuildContext context) => Widget();
}
''',
      [lint(279, 7)],
    );
  }

  Future<void> test_contextMountedInSetState() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
    setState(() {
      if (context.mounted) {
        // do something
      }
    });
  }

  @override
  Widget build(BuildContext context) => Widget();
}
''',
      [lint(279, 15)],
    );
  }

  Future<void> test_thisMountedInSetState() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  void someMethod() {
    setState(() {
      if (this.mounted) {
        // do something
      }
    });
  }

  @override
  Widget build(BuildContext context) => Widget();
}
''',
      [lint(245, 12)],
    );
  }

  Future<void> test_mountedInNestedClosureInsideSetState() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  void someMethod() {
    setState(() {
      final fn = () {
        if (mounted) {}
      };
      fn();
    });
  }

  @override
  Widget build(BuildContext context) => Widget();
}
''',
      [lint(269, 7)],
    );
  }

  Future<void> test_multipleMountedChecksInSetState() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  void someMethod() {
    setState(() {
      if (mounted) {}
      if (context.mounted) {}
    });
  }

  @override
  Widget build(BuildContext context) => Widget();
}
''',
      [lint(245, 7), lint(267, 15)],
    );
  }

  // --- Negative cases: should NOT trigger lint ---

  Future<void> test_mountedCheckBeforeSetState() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  void someMethod() {
    if (context.mounted) {
      setState(() {
        // do something
      });
    }
  }

  @override
  Widget build(BuildContext context) => Widget();
}
''');
  }

  Future<void> test_bareMountedCheckBeforeSetState() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  void someMethod() {
    if (mounted) {
      setState(() {
        // do something
      });
    }
  }

  @override
  Widget build(BuildContext context) => Widget();
}
''');
  }

  Future<void> test_setStateWithoutMounted() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  int _counter = 0;

  void _increment() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) => Widget();
}
''');
  }

  Future<void> test_notAStateClass() async {
    await assertNoDiagnostics(r'''
class NotAState {
  bool get mounted => true;

  void setState(void Function() fn) {
    fn();
  }

  void someMethod() {
    setState(() {
      if (mounted) {}
    });
  }
}
''');
  }

  Future<void> test_setStateWithMethodReference() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  void _update() {}

  void someMethod() {
    setState(_update);
  }

  @override
  Widget build(BuildContext context) => Widget();
}
''');
  }
}
