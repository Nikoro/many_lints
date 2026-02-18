import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/proper_super_calls.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(ProperSuperCallsTest));
}

@reflectiveTest
class ProperSuperCallsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = ProperSuperCalls();

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
  void activate() {}
  void deactivate() {}
  void didUpdateWidget(covariant T oldWidget) {}
  void didChangeDependencies() {}
  void reassemble() {}
  Widget build(BuildContext context);
}
''');

    super.setUp();
  }

  // --- Positive cases: should trigger lint ---

  Future<void> test_initStateSuperNotFirst() async {
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
    _data = 'Hello';
    super.initState();
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      [lint(275, 17)],
    );
  }

  Future<void> test_disposeSuperNotLast() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void dispose() {
    super.dispose();
    print('cleanup');
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      [lint(230, 15)],
    );
  }

  Future<void> test_didUpdateWidgetSuperNotFirst() async {
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
    _data = 'updated';
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      [lint(301, 32)],
    );
  }

  Future<void> test_activateSuperNotFirst() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void activate() {
    print('activating');
    super.activate();
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      [lint(256, 16)],
    );
  }

  Future<void> test_deactivateSuperNotLast() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void deactivate() {
    super.deactivate();
    print('cleanup');
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      [lint(233, 18)],
    );
  }

  Future<void> test_didChangeDependenciesSuperNotFirst() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void didChangeDependencies() {
    print('dependencies changed');
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      [lint(279, 29)],
    );
  }

  Future<void> test_reassembleSuperNotFirst() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void reassemble() {
    print('reassembling');
    super.reassemble();
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      [lint(260, 18)],
    );
  }

  Future<void> test_disposeSuperInMiddle() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void dispose() {
    print('a');
    super.dispose();
    print('b');
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      [lint(246, 15)],
    );
  }

  // --- Negative cases: should NOT trigger lint ---

  Future<void> test_initStateSuperFirst() async {
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

  Future<void> test_disposeSuperLast() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void dispose() {
    print('cleanup');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }

  Future<void> test_didUpdateWidgetSuperFirst() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void didUpdateWidget(MyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('updated');
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }

  Future<void> test_deactivateSuperLast() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void deactivate() {
    print('cleanup');
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }

  Future<void> test_onlySuperCall() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }

  Future<void> test_notAStateClass() async {
    await assertNoDiagnostics(r'''
class NotAState {
  void initState() {
    print('something');
    // No super call, not a State subclass
  }

  void dispose() {
    print('something');
  }
}
''');
  }

  Future<void> test_noSuperCall() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    // No super call — not our concern (other lint handles this)
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }

  Future<void> test_expressionBody() async {
    // Expression bodies can't have multiple statements, so no ordering issue
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

  Future<void> test_customMethodNotChecked() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  void myCustomMethod() {
    print('something');
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }
}
