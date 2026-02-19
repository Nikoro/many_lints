import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_single_setstate.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferSingleSetstateTest));
}

@reflectiveTest
class PreferSingleSetstateTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferSingleSetstate();

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
''');

    super.setUp();
  }

  // --- Positive cases: should trigger lint ---

  Future<void> test_twoConsecutiveSetStateCalls() async {
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

  void _update() {
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
      [lint(301, 40)],
    );
  }

  Future<void> test_threeSetStateCalls() async {
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
  String _c = '';

  void _update() {
    setState(() {
      _a = 'Hello';
    });
    setState(() {
      _b = 'World';
    });
    setState(() {
      _c = '!';
    });
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      [lint(319, 40), lint(365, 36)],
    );
  }

  Future<void> test_nonConsecutiveSetStateCalls() async {
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

  void _update() {
    setState(() {
      _a = 'Hello';
    });
    print('between');
    setState(() {
      _b = 'World';
    });
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      [lint(323, 40)],
    );
  }

  Future<void> test_multipleSetStateInBuild() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  int _a = 0;
  int _b = 0;

  @override
  Widget build(BuildContext context) {
    setState(() {
      _a = 1;
    });
    setState(() {
      _b = 2;
    });
    return const Widget();
  }
}
''',
      [lint(319, 34)],
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
  int _a = 0;
  int _b = 0;

  @override
  void initState() {
    super.initState();
    setState(() {
      _a = 1;
    });
    setState(() {
      _b = 2;
    });
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      [lint(324, 34)],
    );
  }

  // --- Negative cases: should NOT trigger lint ---

  Future<void> test_singleSetStateCall() async {
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

  Future<void> test_setStateInSeparateClosures() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  String _data = '';

  void _setup() {
    final callback1 = () {
      setState(() {
        _data = 'a';
      });
    };
    final callback2 = () {
      setState(() {
        _data = 'b';
      });
    };
    callback1();
    callback2();
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }

  Future<void> test_setStateInDifferentMethods() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  String _data = '';

  void _update1() {
    setState(() {
      _data = 'Hello';
    });
  }

  void _update2() {
    setState(() {
      _data = 'World';
    });
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }

  Future<void> test_notAStateClass() async {
    await assertNoDiagnostics(r'''
class NotAState {
  void setState(void Function() fn) {
    fn();
  }

  void update() {
    setState(() {});
    setState(() {});
  }
}
''');
  }

  Future<void> test_noSetStateCalls() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  String _data = '';

  void _update() {
    _data = 'Hello';
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }
}
