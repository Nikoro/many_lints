import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/use_ref_and_state_synchronously.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(UseRefAndStateSynchronouslyTest),
  );
}

@reflectiveTest
class UseRefAndStateSynchronouslyTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = UseRefAndStateSynchronously();
    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
class Ref {
  T read<T>(Object provider) => throw '';
  T watch<T>(Object provider) => throw '';
  void listen(Object provider, void Function(dynamic, dynamic) listener) {}
  bool get mounted => true;
}

class Notifier<T> {
  Ref get ref => throw '';
  T get state => throw '';
  set state(T value) {}
}

class AsyncNotifier<T> {
  Ref get ref => throw '';
  T get state => throw '';
  set state(T value) {}
}
''');
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_refReadAfterAwait() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  Future<void> doWork() async {
    await Future<void>.delayed(Duration(seconds: 1));
    ref.read(Object());
  }
}
''',
      [lint(173, 18)],
    );
  }

  Future<void> test_stateAssignmentAfterAwait() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  Future<void> doWork() async {
    await Future<void>.delayed(Duration(seconds: 1));
    state = 42;
  }
}
''',
      [lint(173, 10)],
    );
  }

  Future<void> test_refWatchAfterAwait() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  Future<void> doWork() async {
    await Future<void>.delayed(Duration(seconds: 1));
    ref.watch(Object());
  }
}
''',
      [lint(173, 19)],
    );
  }

  Future<void> test_asyncNotifierRefAfterAwait() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends AsyncNotifier<int> {
  Future<void> doWork() async {
    await Future<void>.delayed(Duration(seconds: 1));
    ref.read(Object());
  }
}
''',
      [lint(178, 18)],
    );
  }

  Future<void> test_multipleUsagesAfterAwait() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  Future<void> doWork() async {
    await Future<void>.delayed(Duration(seconds: 1));
    ref.read(Object());
    state = 42;
  }
}
''',
      [lint(173, 18), lint(197, 10)],
    );
  }

  Future<void> test_statePropertyAccessAfterAwait() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<String> {
  Future<void> doWork() async {
    await Future<void>.delayed(Duration(seconds: 1));
    final len = state.length;
  }
}
''',
      [lint(188, 12)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_refBeforeAwait() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  Future<void> doWork() async {
    ref.read(Object());
    await Future<void>.delayed(Duration(seconds: 1));
  }
}
''');
  }

  Future<void> test_stateAssignmentBeforeAwait() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  Future<void> doWork() async {
    state = 42;
    await Future<void>.delayed(Duration(seconds: 1));
  }
}
''');
  }

  Future<void> test_withMountedGuard() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  Future<void> doWork() async {
    await Future<void>.delayed(Duration(seconds: 1));
    if (!ref.mounted) return;
    state = 42;
  }
}
''');
  }

  Future<void> test_withMountedGuardBlock() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  Future<void> doWork() async {
    await Future<void>.delayed(Duration(seconds: 1));
    if (!ref.mounted) {
      return;
    }
    state = 42;
  }
}
''');
  }

  Future<void> test_syncMethod() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  void doWork() {
    ref.read(Object());
    state = 42;
  }
}
''');
  }

  Future<void> test_nonNotifierClass() async {
    await assertNoDiagnostics(r'''
class Ref {
  Object read(Object provider) => provider;
  bool get mounted => true;
}

class MyClass {
  final Ref ref = Ref();
  int state = 0;

  Future<void> doWork() async {
    await Future<void>.delayed(Duration(seconds: 1));
    ref.read(Object());
    state = 42;
  }
}
''');
  }

  Future<void> test_refInClosureAfterAwait() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  Future<void> doWork() async {
    await Future<void>.delayed(Duration(seconds: 1));
    final callback = () {
      ref.read(Object());
    };
  }
}
''');
  }

  Future<void> test_refMountedCheckAfterAwait() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  Future<void> doWork() async {
    await Future<void>.delayed(Duration(seconds: 1));
    if (!ref.mounted) return;
  }
}
''');
  }
}
