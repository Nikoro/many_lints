import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/avoid_hooks_outside_build.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidHooksOutsideBuildTest),
  );
}

@reflectiveTest
class AvoidHooksOutsideBuildTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidHooksOutsideBuild();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {
  const Widget();
}
class BuildContext {}
class StatelessWidget extends Widget {
  const StatelessWidget();
  Widget build(BuildContext context) => const Widget();
}
class StatefulWidget extends Widget {
  const StatefulWidget();
}
class State<T extends StatefulWidget> {
  void initState() {}
  void dispose() {}
  Widget build(BuildContext context) => const Widget();
}
class Text extends Widget {
  const Text(this.data);
  final String data;
}
class ElevatedButton extends Widget {
  const ElevatedButton({required this.onPressed, required this.child});
  final void Function()? onPressed;
  final Widget child;
}
''');
    newPackage('flutter_hooks').addFile('lib/flutter_hooks.dart', r'''
import 'package:flutter/widgets.dart';
export 'package:flutter/widgets.dart';

class HookWidget extends Widget {
  const HookWidget();
  Widget build(BuildContext context) => const Widget();
}

class HookBuilder extends Widget {
  const HookBuilder({required this.builder});
  final Widget Function(BuildContext) builder;
}

class ValueNotifier<T> {
  ValueNotifier(this.value);
  T value;
}

ValueNotifier<T> useState<T>(T initial) => ValueNotifier<T>(initial);
T useMemoized<T>(T Function() factory) => factory();
void useEffect(void Function()? Function() effect) {}
''');
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_hookInEventHandler() async {
    await assertDiagnostics(
      r'''
import 'package:flutter_hooks/flutter_hooks.dart';

class MyWidget extends HookWidget {
  const MyWidget();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        useState(0);
      },
      child: const Text('tap'),
    );
  }
}
''',
      [lint(217, 11)],
    );
  }

  Future<void> test_hookInPlainMethod() async {
    await assertDiagnostics(
      r'''
import 'package:flutter_hooks/flutter_hooks.dart';

class MyWidget extends HookWidget {
  const MyWidget();

  void helper() {
    useState(0);
  }

  @override
  Widget build(BuildContext context) => const Text('x');
}
''',
      [lint(131, 11)],
    );
  }

  Future<void> test_hookInStatelessWidgetBuild() async {
    await assertDiagnostics(
      r'''
import 'package:flutter_hooks/flutter_hooks.dart';

class MyWidget extends StatelessWidget {
  const MyWidget();

  @override
  Widget build(BuildContext context) {
    final counter = useState(0);
    return const Text('x');
  }
}
''',
      [lint(185, 11)],
    );
  }

  Future<void> test_hookInPlainTopLevelFunction() async {
    await assertDiagnostics(
      r'''
import 'package:flutter_hooks/flutter_hooks.dart';

void setupThings() {
  useState(0);
}
''',
      [lint(75, 11)],
    );
  }

  Future<void> test_hookInInitState() async {
    await assertDiagnostics(
      r'''
import 'package:flutter_hooks/flutter_hooks.dart';

class MyWidget extends StatefulWidget {
  const MyWidget();
}

class MyState extends State<MyWidget> {
  @override
  void initState() {
    useState(0);
  }
}
''',
      [lint(192, 11)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_hookInHookWidgetBuild() async {
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

  Future<void> test_hookInCustomHookFunction() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_hooks/flutter_hooks.dart';

ValueNotifier<int> useCounter() {
  return useState(0);
}
''');
  }

  Future<void> test_hookInPrivateHookFunction() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_hooks/flutter_hooks.dart';

ValueNotifier<int> _useCounter() {
  return useState(0);
}
''');
  }

  Future<void> test_hookInHookBuilderBuilder() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_hooks/flutter_hooks.dart';

class MyWidget extends StatelessWidget {
  const MyWidget();

  @override
  Widget build(BuildContext context) {
    return HookBuilder(
      builder: (context) {
        final counter = useState(0);
        return Text('${counter.value}');
      },
    );
  }
}
''');
  }

  Future<void> test_nonHookNamedFunction() async {
    await assertNoDiagnostics(r'''
int userCount() => 0;

void setupThings() {
  // "userCount" starts with "use" but is not a hook name
  userCount();
}
''');
  }

  Future<void> test_qualifiedCallIsNotAHook() async {
    await assertNoDiagnostics(r'''
class Controller {
  void useResource() {}
}

void setupThings() {
  Controller().useResource();
}
''');
  }
}
