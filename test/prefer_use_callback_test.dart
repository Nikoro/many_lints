import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_use_callback.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferUseCallbackTest));
}

@reflectiveTest
class PreferUseCallbackTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferUseCallback();
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

  Future<void> test_useMemoizedReturningClosure() async {
    await assertDiagnostics(
      r'''
import 'package:flutter_hooks/flutter_hooks.dart';
void fn() {
  useMemoized(() => () {});
}
''',
      [lint(65, 24)],
    );
  }

  Future<void> test_useMemoizedReturningClosureWithKeys() async {
    await assertDiagnostics(
      r'''
import 'package:flutter_hooks/flutter_hooks.dart';
void fn() {
  useMemoized(() => () {}, []);
}
''',
      [lint(65, 28)],
    );
  }

  Future<void> test_useMemoizedReturningArrowClosure() async {
    await assertDiagnostics(
      r'''
import 'package:flutter_hooks/flutter_hooks.dart';
void fn() {
  useMemoized(() => (int x) => x + 1);
}
''',
      [lint(65, 35)],
    );
  }

  Future<void> test_useMemoizedReturningTearOff() async {
    await assertDiagnostics(
      r'''
import 'package:flutter_hooks/flutter_hooks.dart';
void myMethod() {}
void fn() {
  useMemoized(() => myMethod);
}
''',
      [lint(84, 27)],
    );
  }

  Future<void> test_useMemoizedBlockBodyReturningClosure() async {
    await assertDiagnostics(
      r'''
import 'package:flutter_hooks/flutter_hooks.dart';
void fn() {
  useMemoized(() { return () {}; });
}
''',
      [lint(65, 33)],
    );
  }

  // --- Negative cases: should NOT trigger the lint ---

  Future<void> test_useMemoizedReturningNonFunction() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_hooks/flutter_hooks.dart';
void fn() {
  useMemoized(() => 42);
}
''');
  }

  Future<void> test_useMemoizedReturningString() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_hooks/flutter_hooks.dart';
void fn() {
  useMemoized(() => 'hello');
}
''');
  }

  Future<void> test_useMemoizedWithMultiStatementBlock() async {
    // Block body with more than one statement — not a simple return
    await assertNoDiagnostics(r'''
import 'package:flutter_hooks/flutter_hooks.dart';
void fn() {
  useMemoized(() {
    final x = 1;
    return () => x;
  });
}
''');
  }

  Future<void> test_useCallbackNotFlagged() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_hooks/flutter_hooks.dart';
void fn() {
  useCallback(() {}, []);
}
''');
  }

  Future<void> test_useStateNotFlagged() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_hooks/flutter_hooks.dart';
void fn() {
  useState(0);
}
''');
  }

  Future<void> test_useMemoizedReturningObjectExpression() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_hooks/flutter_hooks.dart';
void fn() {
  useMemoized(() => [1, 2, 3]);
}
''');
  }
}
