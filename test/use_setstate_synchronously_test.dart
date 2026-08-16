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
