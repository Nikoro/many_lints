import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_ref_read_inside_build.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidRefReadInsideBuildTest),
  );
}

@reflectiveTest
class AvoidRefReadInsideBuildTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidRefReadInsideBuild();
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

  Future<void> test_refReadInConsumerWidgetBuild() async {
    await assertDiagnostics(
      r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.read(Object());
    return Widget();
  }
}
''',
      [lint(182, 18)],
    );
  }

  Future<void> test_refReadInConsumerStateBuild() async {
    await assertDiagnostics(
      r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState extends ConsumerState<ConsumerStatefulWidget> {
  @override
  Widget build(BuildContext context) {
    final value = ref.read(Object());
    return Widget();
  }
}
''',
      [lint(189, 18)],
    );
  }

  Future<void> test_multipleRefReadsInBuild() async {
    await assertDiagnostics(
      r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.read(Object());
    final b = ref.read(Object());
    return Widget();
  }
}
''',
      [lint(178, 18), lint(212, 18)],
    );
  }

  Future<void> test_hookConsumerWidgetRefRead() async {
    await assertDiagnostics(
      r'''
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MyWidget extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.read(Object());
    return Widget();
  }
}
''',
      [lint(182, 18)],
    );
  }

  Future<void> test_hookConsumerStateRefRead() async {
    await assertDiagnostics(
      r'''
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MyState extends HookConsumerState<HookConsumerStatefulWidget> {
  @override
  Widget build(BuildContext context) {
    final value = ref.read(Object());
    return Widget();
  }
}
''',
      [lint(193, 18)],
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

  Future<void> test_refReadInsideClosureInBuild() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onPressed = () {
      ref.read(Object());
    };
    return Widget();
  }
}
''');
  }

  Future<void> test_refReadInsideNamedCallbackInBuild() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void onPressed() {
      ref.read(Object());
    }
    return Widget();
  }
}
''');
  }

  Future<void> test_refReadInNonBuildMethod() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState extends ConsumerState<ConsumerStatefulWidget> {
  void someMethod() {
    ref.read(Object());
  }

  @override
  Widget build(BuildContext context) {
    return Widget();
  }
}
''');
  }

  Future<void> test_refReadInNonConsumerClass() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Ref {
  Object read(Object provider) => provider;
}

class MyWidget extends Widget {
  final Ref ref = Ref();

  Widget build(BuildContext context) {
    final value = ref.read(Object());
    return Widget();
  }
}
''');
  }

  Future<void> test_refListenInBuild() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(Object(), (a, b) {});
    return Widget();
  }
}
''');
  }
}
