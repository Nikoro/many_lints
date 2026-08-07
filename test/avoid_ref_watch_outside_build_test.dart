import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_ref_watch_outside_build.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidRefWatchOutsideBuildTest),
  );
}

@reflectiveTest
class AvoidRefWatchOutsideBuildTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidRefWatchOutsideBuild();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {}
class BuildContext {}
class StatefulWidget extends Widget {}
class State<T extends StatefulWidget> {
  void initState() {}
  void dispose() {}
}
''');
    newPackage('flutter_riverpod').addFile('lib/flutter_riverpod.dart', r'''
import 'package:flutter/widgets.dart';
export 'package:flutter/widgets.dart';
class Ref {
  T read<T>(Object provider) => throw '';
  T watch<T>(Object provider) => throw '';
  void listen(Object provider, void Function(dynamic, dynamic) listener) {}
}
class WidgetRef extends Ref {}
class ConsumerWidget extends Widget {
  Widget build(BuildContext context, WidgetRef ref) => Widget();
}
class ConsumerStatefulWidget extends StatefulWidget {
  ConsumerState createState() => throw '';
}
class ConsumerState<T extends ConsumerStatefulWidget> extends State<T> {
  WidgetRef get ref => throw '';
  Widget build(BuildContext context) => Widget();
}
''');
    newPackage('hooks_riverpod').addFile('lib/hooks_riverpod.dart', r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
export 'package:flutter/widgets.dart';
export 'package:flutter_riverpod/flutter_riverpod.dart';
class HookConsumerWidget extends Widget {
  Widget build(BuildContext context, WidgetRef ref) => Widget();
}
class HookConsumerStatefulWidget extends StatefulWidget {
  HookConsumerState createState() => throw '';
}
class HookConsumerState<T extends HookConsumerStatefulWidget> extends State<T> {
  WidgetRef get ref => throw '';
  Widget build(BuildContext context) => Widget();
}
''');
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_refWatchInInitState() async {
    await assertDiagnostics(
      r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState extends ConsumerState<ConsumerStatefulWidget> {
  @override
  void initState() {
    final value = ref.watch(Object());
  }

  @override
  Widget build(BuildContext context) => Widget();
}
''',
      [lint(171, 19)],
    );
  }

  Future<void> test_refWatchInDispose() async {
    await assertDiagnostics(
      r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState extends ConsumerState<ConsumerStatefulWidget> {
  @override
  void dispose() {
    ref.watch(Object());
  }

  @override
  Widget build(BuildContext context) => Widget();
}
''',
      [lint(155, 19)],
    );
  }

  Future<void> test_refWatchInsideCallbackInHelperMethod() async {
    await assertDiagnostics(
      r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState extends ConsumerState<ConsumerStatefulWidget> {
  void onTap() {
    final handler = () {
      ref.watch(Object());
    };
  }

  @override
  Widget build(BuildContext context) => Widget();
}
''',
      [lint(168, 19)],
    );
  }

  Future<void> test_refWatchInHookConsumerStateMethod() async {
    await assertDiagnostics(
      r'''
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MyState extends HookConsumerState<HookConsumerStatefulWidget> {
  void refresh() {
    ref.watch(Object());
  }

  @override
  Widget build(BuildContext context) => Widget();
}
''',
      [lint(147, 19)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_refWatchInBuild() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(Object());
    return Widget();
  }
}
''');
  }

  Future<void> test_refReadOutsideBuild() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState extends ConsumerState<ConsumerStatefulWidget> {
  void onTap() {
    ref.read(Object());
  }

  @override
  Widget build(BuildContext context) => Widget();
}
''');
  }

  Future<void> test_refListenOutsideBuild() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState extends ConsumerState<ConsumerStatefulWidget> {
  void onTap() {
    ref.listen(Object(), (a, b) {});
  }

  @override
  Widget build(BuildContext context) => Widget();
}
''');
  }

  Future<void> test_watchOnNonRefTargetInNonConsumerClass() async {
    await assertNoDiagnostics(r'''
class Ref {
  Object watch(Object provider) => provider;
}

class MyClass {
  final Ref ref = Ref();

  void doWork() {
    ref.watch(Object());
  }
}
''');
  }

  Future<void> test_watchOnDifferentReceiver() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Observer {
  Object watch(Object o) => o;
}

class MyState extends ConsumerState<ConsumerStatefulWidget> {
  final Observer observer = Observer();

  void onTap() {
    observer.watch(Object());
  }

  @override
  Widget build(BuildContext context) => Widget();
}
''');
  }
}
