import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_use_prefix.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferUsePrefixTest));
}

@reflectiveTest
class PreferUsePrefixTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferUsePrefix();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {}
class BuildContext {}
class StatelessWidget extends Widget {
  Widget build(BuildContext context) => Widget();
}
''');
    newPackage('flutter_hooks').addFile('lib/flutter_hooks.dart', r'''
import 'package:flutter/widgets.dart';
class HookWidget extends Widget {
  Widget build(BuildContext context) => Widget();
}
T useState<T>(T initialData) => initialData;
T useMemoized<T>(T Function() valueBuilder, [List<Object?>? keys]) =>
    valueBuilder();
T useCallback<T extends Function>(T callback, [List<Object?>? keys]) =>
    callback;
class HookBuilder extends Widget {
  HookBuilder({required Widget Function(BuildContext) builder});
}
''');
    super.setUp();
  }

  // --- Positive cases: should trigger the lint ---

  Future<void> test_topLevelFunctionCallingHook() async {
    await assertDiagnostics(
      r'''
import 'package:flutter_hooks/flutter_hooks.dart';
String myCustomHook() {
  return useMemoized(() => 'hello');
}
''',
      [lint(58, 12)],
    );
  }

  Future<void> test_privateFunctionCallingHook() async {
    await assertDiagnostics(
      r'''
import 'package:flutter_hooks/flutter_hooks.dart';
int _myPrivateHook() {
  return useState(0);
}
''',
      [lint(55, 14)],
    );
  }

  Future<void> test_methodInClassCallingHook() async {
    await assertDiagnostics(
      r'''
import 'package:flutter_hooks/flutter_hooks.dart';
class MyClass {
  int getCounter() {
    return useState(0);
  }
}
''',
      [lint(73, 10)],
    );
  }

  Future<void> test_methodInHookWidgetNonBuild() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
class MyWidget extends HookWidget {
  int _fetchData() {
    return useState(42);
  }
  @override
  Widget build(BuildContext context) {
    return Widget();
  }
}
''',
      [lint(132, 10)],
    );
  }

  Future<void> test_functionWithMultipleHookCalls() async {
    await assertDiagnostics(
      r'''
import 'package:flutter_hooks/flutter_hooks.dart';
void setupHooks() {
  useState(0);
  useMemoized(() => 'cached');
}
''',
      [lint(56, 10)],
    );
  }

  // --- Negative cases: should NOT trigger the lint ---

  Future<void> test_functionWithUsePrefix() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_hooks/flutter_hooks.dart';
String useCustomHook() {
  return useMemoized(() => 'hello');
}
''');
  }

  Future<void> test_privateFunctionWithUsePrefix() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_hooks/flutter_hooks.dart';
int _usePrivateHook() {
  return useState(0);
}
''');
  }

  Future<void> test_functionWithoutHookCalls() async {
    await assertNoDiagnostics(r'''
int regularFunction() {
  return 42;
}
''');
  }

  Future<void> test_buildMethodInHookWidget() async {
    // The build method itself is not a custom hook — it's the standard
    // widget build method. It should NOT be flagged.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
class MyWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final value = useState(0);
    return Widget();
  }
}
''');
  }

  Future<void> test_methodCallingNonHookFunction() async {
    await assertNoDiagnostics(r'''
class MyClass {
  void doStuff() {
    print('hello');
  }
}
''');
  }

  Future<void> test_hookBuilderBuilderCallback() async {
    // The builder callback inside HookBuilder is not a named function,
    // so it doesn't need the use prefix.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
Widget myWidget() {
  return HookBuilder(builder: (context) {
    final value = useState(0);
    return Widget();
  });
}
''');
  }
}
