import 'package:many_lints/src/rules/use_setstate_synchronously.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(UseSetstateSynchronouslyTest),
  );
}

@reflectiveTest
class UseSetstateSynchronouslyTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = UseSetstateSynchronously();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class BuildContext {}
class Key {}
class Widget {
  const Widget({this.key});
  final Key? key;
}
class StatefulWidget extends Widget {
  const StatefulWidget({super.key});
  State createState() => throw UnimplementedError();
}
abstract class State<T extends StatefulWidget> {
  bool get mounted => true;
  void setState(void Function() fn) {}
  void initState() {}
  void dispose() {}
  Widget build(BuildContext context);
}
''');
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_setStateAfterAwait() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  Future<void> load() async {
    await Future<void>.delayed(Duration.zero);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      [lint(307, 8)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_guardedSetState() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  Future<void> load() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }

  Future<void> test_setStateBeforeAwait() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  Future<void> load() async {
    setState(() {});
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }

  Future<void> test_synchronousMethod() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  void update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }

  Future<void> test_positiveGuardWrappingTheCall() async {
    // `if (mounted) setState(...)` is what you write when there is nothing to
    // do after the guard, so an early return would be noise.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  Future<void> load() async {
    await Future<void>.delayed(Duration.zero);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }

  Future<void> test_positiveGuardWithABlockBody() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  Future<void> load() async {
    await Future<void>.delayed(Duration.zero);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }

  Future<void> test_positiveGuardWithAConjunction() async {
    // Entering the branch requires `mounted`, whatever the other operand says.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  bool ready = false;

  Future<void> load() async {
    await Future<void>.delayed(Duration.zero);
    if (mounted && ready) setState(() {});
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }

  Future<void> test_earlyReturnGuardWithADisjunction() async {
    // The return fires whenever `mounted` is false, so reaching the line
    // below still proves the widget is mounted.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  Future<bool> save() async => true;

  Future<void> load() async {
    final succeeded = await save();
    if (!mounted || succeeded) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_outsideAStateClass() async {
    await assertNoDiagnostics(r'''
class NotAState {
  void setState(void Function() fn) {}

  Future<void> load() async {
    await Future<void>.delayed(Duration.zero);
    setState(() {});
  }
}
''');
  }

  Future<void> test_awaitInsideThePositiveGuardReopensTheGap() async {
    // The guard proves `mounted` when the branch is entered; the await inside
    // it opens a fresh gap the guard says nothing about.
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  Future<void> load() async {
    await Future<void>.delayed(Duration.zero);
    if (mounted) {
      await Future<void>.delayed(Duration.zero);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      [lint(377, 8)],
    );
  }

  Future<void> test_elseBranchOfThePositiveGuardIsUnguarded() async {
    // The else runs precisely when `mounted` was false.
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  Future<void> load() async {
    await Future<void>.delayed(Duration.zero);
    if (mounted) {} else { setState(() {}); }
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      [lint(330, 8)],
    );
  }

  Future<void> test_positiveGuardWithADisjunctionDoesNotProveMounted() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  bool ready = false;

  Future<void> load() async {
    await Future<void>.delayed(Duration.zero);
    if (mounted || ready) setState(() {});
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      [lint(352, 8)],
    );
  }

  Future<void>
  test_earlyReturnGuardWithAConjunctionDoesNotProveMounted() async {
    // `if (!mounted && failed) return;` falls through while unmounted
    // whenever `failed` is false.
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  bool failed = false;

  Future<void> load() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted && failed) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      [lint(367, 8)],
    );
  }

  Future<void> test_severalAwaitsReportEachUnguardedCall() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  Future<void> load() async {
    await Future<void>.delayed(Duration.zero);
    setState(() {});
    await Future<void>.delayed(Duration.zero);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      [lint(307, 8), lint(375, 8)],
    );
  }
}
