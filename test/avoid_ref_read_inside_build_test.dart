import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/avoid_ref_read_inside_build.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidRefReadInsideBuildTest),
  );
}

@reflectiveTest
class AvoidRefReadInsideBuildTest extends ManyLintsRuleTest {
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
    // package:provider reaches the same two operations through extensions on
    // BuildContext, which is why the rule matches on the receiver's TYPE.
    newPackage('provider').addFile('lib/provider.dart', r'''
import 'package:flutter/widgets.dart';
export 'package:flutter/widgets.dart';
extension ReadContext on BuildContext {
  T read<T>() => throw '';
}
extension WatchContext on BuildContext {
  T watch<T>() => throw '';
}
''');
    super.setUp();
  }

  // ---- package:provider ----

  Future<void> test_contextReadInWidgetBuild() async {
    await assertDiagnostics(
      r'''
import 'package:provider/provider.dart';

class MyWidget extends Widget {
  Widget build(BuildContext context) {
    final value = context.read<int>();
    return Widget();
  }
}
''',
      [lint(131, 19)],
    );
  }

  // `context.watch` is the subscribing read, which is what belongs in build.
  Future<void> test_contextWatchInBuildIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:provider/provider.dart';

class MyWidget extends Widget {
  Widget build(BuildContext context) {
    final value = context.watch<int>();
    return Widget();
  }
}
''');
  }

  // A BuildContext under any other name is the same call, which is what
  // matching the receiver's type buys over matching its name.
  Future<void> test_contextReadThroughRenamedReceiver() async {
    await assertDiagnostics(
      r'''
import 'package:provider/provider.dart';

class MyWidget extends Widget {
  Widget build(BuildContext ctx) {
    final value = ctx.read<int>();
    return Widget();
  }
}
''',
      [lint(127, 15)],
    );
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
