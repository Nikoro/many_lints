import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_ref_inside_state_dispose.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidRefInsideStateDisposeTest),
  );
}

@reflectiveTest
class AvoidRefInsideStateDisposeTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidRefInsideStateDispose();
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

  Future<void> test_refReadInDispose() async {
    await assertDiagnostics(
      r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState extends ConsumerState<ConsumerStatefulWidget> {
  @override
  void dispose() {
    ref.read(Object());
    super.dispose();
  }
}
''',
      [lint(155, 18)],
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
    super.dispose();
  }
}
''',
      [lint(155, 19)],
    );
  }

  Future<void> test_refListenInDispose() async {
    await assertDiagnostics(
      r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState extends ConsumerState<ConsumerStatefulWidget> {
  @override
  void dispose() {
    ref.listen(Object(), (a, b) {});
    super.dispose();
  }
}
''',
      [lint(155, 31)],
    );
  }

  Future<void> test_multipleRefUsagesInDispose() async {
    await assertDiagnostics(
      r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState extends ConsumerState<ConsumerStatefulWidget> {
  @override
  void dispose() {
    ref.read(Object());
    ref.watch(Object());
    super.dispose();
  }
}
''',
      [lint(155, 18), lint(179, 19)],
    );
  }

  Future<void> test_hookConsumerStateRefInDispose() async {
    await assertDiagnostics(
      r'''
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MyState extends HookConsumerState<HookConsumerStatefulWidget> {
  @override
  void dispose() {
    ref.read(Object());
    super.dispose();
  }
}
''',
      [lint(159, 18)],
    );
  }

  Future<void> test_noRefInDispose() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState extends ConsumerState<ConsumerStatefulWidget> {
  @override
  void dispose() {
    super.dispose();
  }
}
''');
  }

  Future<void> test_refInBuildMethod() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState extends ConsumerState<ConsumerStatefulWidget> {
  @override
  Widget build(BuildContext context) {
    ref.watch(Object());
    return Widget();
  }
}
''');
  }

  Future<void> test_refInInitState() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState extends ConsumerState<ConsumerStatefulWidget> {
  @override
  void initState() {
    super.initState();
    ref.read(Object());
  }
}
''');
  }

  Future<void> test_nonConsumerStateDispose() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyState extends State<StatefulWidget> {
  @override
  void dispose() {
    super.dispose();
  }
}
''');
  }

  Future<void> test_refInClosureInsideDispose() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState extends ConsumerState<ConsumerStatefulWidget> {
  @override
  void dispose() {
    final fn = () {
      ref.read(Object());
    };
    super.dispose();
  }
}
''');
  }
}
