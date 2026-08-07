import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_misused_hooks.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidMisusedHooksTest));
}

@reflectiveTest
class AvoidMisusedHooksTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidMisusedHooks();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {
  const Widget();
}
class BuildContext {}
class StatelessWidget extends Widget {
  const StatelessWidget();
  Widget build(BuildContext context) => const Widget();
}
class Text extends Widget {
  const Text(this.data);
  final String data;
}
class Column extends Widget {
  const Column({this.children = const []});
  final List<Widget> children;
}
''');
    newPackage('flutter_hooks').addFile('lib/flutter_hooks.dart', r'''
import 'package:flutter/widgets.dart';
export 'package:flutter/widgets.dart';

class HookWidget extends Widget {
  const HookWidget();
  Widget build(BuildContext context) => const Widget();
}

class ValueNotifier<T> {
  ValueNotifier(this.value);
  T value;
}

ValueNotifier<T> useState<T>(T initial) => ValueNotifier<T>(initial);
T useMemoized<T>(T Function() factory) => factory();
''');
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_hookInForLoop() async {
    await assertDiagnostics(
      r'''
import 'package:flutter_hooks/flutter_hooks.dart';

class MyWidget extends HookWidget {
  const MyWidget();

  @override
  Widget build(BuildContext context) {
    for (var i = 0; i < 3; i++) {
      useState(i);
    }
    return const Text('x');
  }
}
''',
      [lint(200, 11)],
    );
  }

  Future<void> test_hookInForInLoop() async {
    await assertDiagnostics(
      r'''
import 'package:flutter_hooks/flutter_hooks.dart';

class MyWidget extends HookWidget {
  const MyWidget();

  @override
  Widget build(BuildContext context) {
    for (final item in [1, 2, 3]) {
      useState(item);
    }
    return const Text('x');
  }
}
''',
      [lint(202, 14)],
    );
  }

  Future<void> test_hookInWhileLoop() async {
    await assertDiagnostics(
      r'''
import 'package:flutter_hooks/flutter_hooks.dart';

class MyWidget extends HookWidget {
  const MyWidget();

  @override
  Widget build(BuildContext context) {
    var i = 0;
    while (i < 3) {
      useState(i);
      i++;
    }
    return const Text('x');
  }
}
''',
      [lint(201, 11)],
    );
  }

  Future<void> test_hookInForElement() async {
    await assertDiagnostics(
      r'''
import 'package:flutter_hooks/flutter_hooks.dart';

class MyWidget extends HookWidget {
  const MyWidget();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++) Text('${useState(i).value}'),
      ],
    );
  }
}
''',
      [lint(241, 11)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_hookAtTopLevelOfBuild() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_hooks/flutter_hooks.dart';

class MyWidget extends HookWidget {
  const MyWidget();

  @override
  Widget build(BuildContext context) {
    final counter = useState(0);
    return Text('${counter.value}');
  }
}
''');
  }

  Future<void> test_loopWithoutHook() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_hooks/flutter_hooks.dart';

class MyWidget extends HookWidget {
  const MyWidget();

  @override
  Widget build(BuildContext context) {
    final counter = useState(0);
    for (var i = 0; i < 3; i++) {
      counter.value = i;
    }
    return Text('${counter.value}');
  }
}
''');
  }

  Future<void> test_hookBeforeLoop() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_hooks/flutter_hooks.dart';

class MyWidget extends HookWidget {
  const MyWidget();

  @override
  Widget build(BuildContext context) {
    final counter = useState(0);
    for (var i = 0; i < 3; i++) {}
    return Text('${counter.value}');
  }
}
''');
  }

  Future<void> test_hookInClosureInsideLoopBody() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_hooks/flutter_hooks.dart';

ValueNotifier<int> useCounter() => useState(0);

class MyWidget extends HookWidget {
  const MyWidget();

  @override
  Widget build(BuildContext context) {
    final counter = useState(0);
    return Text('${counter.value}');
  }
}
''');
  }

  Future<void> test_qualifiedCallInLoop() async {
    await assertNoDiagnostics(r'''
class Controller {
  void useResource() {}
}

void setup() {
  final controller = Controller();
  for (var i = 0; i < 3; i++) {
    controller.useResource();
  }
}
''');
  }

  Future<void> test_nonHookNameInLoop() async {
    await assertNoDiagnostics(r'''
int userCount() => 0;

void setup() {
  for (var i = 0; i < 3; i++) {
    userCount();
  }
}
''');
  }
}
