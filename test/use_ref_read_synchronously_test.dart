import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/use_ref_read_synchronously.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(UseRefReadSynchronouslyTest),
  );
}

@reflectiveTest
class UseRefReadSynchronouslyTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = UseRefReadSynchronously();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class BuildContext {
  bool get mounted => true;
}

class Widget {}
class StatelessWidget extends Widget {
  Widget build(BuildContext context) => Widget();
}
''');
    newPackage('flutter_riverpod').addFile('lib/flutter_riverpod.dart', r'''
import 'package:flutter/widgets.dart';

class WidgetRef {
  T read<T>(Object provider) => throw '';
  T watch<T>(Object provider) => throw '';
  void listen(Object provider, void Function(dynamic, dynamic) listener) {}
}

class ConsumerWidget extends StatelessWidget {
  Widget build(BuildContext context, [WidgetRef? ref]) => Widget();
}

class ConsumerState<T extends ConsumerWidget> {
  WidgetRef get ref => throw '';
  bool get mounted => true;
  BuildContext get context => throw '';
  Widget build(BuildContext context) => Widget();
}
''');
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_refReadAfterAwaitInAsyncMethod() async {
    // Standalone async methods (not inside build) should NOT trigger
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, [WidgetRef? ref]) {
    return StatelessWidget();
  }

  void _onTap(WidgetRef ref) async {
    await Future<void>.delayed(Duration(seconds: 1));
    ref.read(Object());
  }
}
''');
  }

  Future<void> test_refReadAfterAwaitInBuildCallback() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, [WidgetRef? ref]) {
    final onTap = () async {
      await Future<void>.delayed(Duration(seconds: 1));
      ref!.read(Object());
    };
    return StatelessWidget();
  }
}
''',
      [lint(297, 19)],
    );
  }

  Future<void> test_refReadAfterAwaitInConsumerState() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState extends ConsumerState<ConsumerWidget> {
  @override
  Widget build(BuildContext context) {
    final onTap = () async {
      await Future<void>.delayed(Duration(seconds: 1));
      ref.read(Object());
    };
    return StatelessWidget();
  }
}
''',
      [lint(293, 18)],
    );
  }

  Future<void> test_multipleRefReadsAfterAwait() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState extends ConsumerState<ConsumerWidget> {
  @override
  Widget build(BuildContext context) {
    final onTap = () async {
      await Future<void>.delayed(Duration(seconds: 1));
      ref.read(Object());
      ref.read(Object());
    };
    return StatelessWidget();
  }
}
''',
      [lint(293, 18), lint(319, 18)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_refReadBeforeAwait() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState extends ConsumerState<ConsumerWidget> {
  @override
  Widget build(BuildContext context) {
    final onTap = () async {
      ref.read(Object());
      await Future<void>.delayed(Duration(seconds: 1));
    };
    return StatelessWidget();
  }
}
''');
  }

  Future<void> test_refReadInSyncCallback() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState extends ConsumerState<ConsumerWidget> {
  @override
  Widget build(BuildContext context) {
    final onTap = () {
      ref.read(Object());
    };
    return StatelessWidget();
  }
}
''');
  }

  Future<void> test_refReadWithMountedGuard() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState extends ConsumerState<ConsumerWidget> {
  @override
  Widget build(BuildContext context) {
    final onTap = () async {
      await Future<void>.delayed(Duration(seconds: 1));
      if (!mounted) return;
      ref.read(Object());
    };
    return StatelessWidget();
  }
}
''');
  }

  Future<void> test_refReadWithContextMountedGuard() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState extends ConsumerState<ConsumerWidget> {
  @override
  Widget build(BuildContext context) {
    final onTap = () async {
      await Future<void>.delayed(Duration(seconds: 1));
      if (!context.mounted) return;
      ref.read(Object());
    };
    return StatelessWidget();
  }
}
''');
  }

  Future<void> test_refReadWithMountedGuardBlock() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState extends ConsumerState<ConsumerWidget> {
  @override
  Widget build(BuildContext context) {
    final onTap = () async {
      await Future<void>.delayed(Duration(seconds: 1));
      if (!mounted) {
        return;
      }
      ref.read(Object());
    };
    return StatelessWidget();
  }
}
''');
  }

  Future<void> test_refWatchNotFlagged() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState extends ConsumerState<ConsumerWidget> {
  @override
  Widget build(BuildContext context) {
    final onTap = () async {
      await Future<void>.delayed(Duration(seconds: 1));
      ref.watch(Object());
    };
    return StatelessWidget();
  }
}
''');
  }

  Future<void> test_nonConsumerWidget() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final onTap = () async {
      await Future<void>.delayed(Duration(seconds: 1));
    };
    return StatelessWidget();
  }
}
''');
  }

  Future<void> test_refReadInNestedClosure() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState extends ConsumerState<ConsumerWidget> {
  @override
  Widget build(BuildContext context) {
    final onTap = () async {
      await Future<void>.delayed(Duration(seconds: 1));
      final callback = () {
        ref.read(Object());
      };
    };
    return StatelessWidget();
  }
}
''');
  }
}
