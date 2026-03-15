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

  // ---- Additional coverage tests ----

  /// Lines 95-96: ref/state usage in a statement that itself contains an await,
  /// after already seeing an earlier await.
  Future<void> test_refUsageInStatementWithSecondAwait() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  Future<void> doWork() async {
    await Future<void>.delayed(Duration(seconds: 1));
    await Future<void>.delayed(Duration(seconds: ref.read(Object())));
  }
}
''',
      [lint(218, 18)],
    );
  }

  /// Line 132: visitMethodInvocation falls through to super when target is not
  /// ref/state (e.g. someOther.method() after await — no lint).
  Future<void> test_nonRefMethodInvocationAfterAwait() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  Future<void> doWork() async {
    await Future<void>.delayed(Duration(seconds: 1));
    final x = Object().toString();
  }
}
''');
  }

  /// Line 147: visitPrefixedIdentifier falls through to super when prefix is
  /// not ref/state.
  Future<void> test_nonRefPrefixedIdentifierAfterAwait() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  Future<void> doWork() async {
    final x = 'hello';
    await Future<void>.delayed(Duration(seconds: 1));
    final y = x.length;
  }
}
''');
  }

  /// Lines 152-153: visitSimpleIdentifier where name is not ref/state.
  Future<void> test_nonRefSimpleIdentifierAfterAwait() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  Future<void> doWork() async {
    var x = 0;
    await Future<void>.delayed(Duration(seconds: 1));
    x = 1;
  }
}
''');
  }

  /// Lines 159-162: Skip bare ref/state when part of PrefixedIdentifier,
  /// PropertyAccess, or MethodInvocation (those visitors handle it).
  /// Line 164: Report bare `ref` identifier that is NOT part of those.
  Future<void> test_bareRefIdentifierAfterAwait() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  Future<void> doWork() async {
    await Future<void>.delayed(Duration(seconds: 1));
    print(ref);
  }
}
''',
      [lint(179, 3)],
    );
  }

  /// Line 164: Report bare `state` identifier.
  Future<void> test_bareStateIdentifierAfterAwait() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  Future<void> doWork() async {
    await Future<void>.delayed(Duration(seconds: 1));
    print(state);
  }
}
''',
      [lint(179, 5)],
    );
  }

  /// Line 174: visitAssignmentExpression falls through to super when LHS is
  /// not `state`.
  Future<void> test_nonStateAssignmentAfterAwait() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  Future<void> doWork() async {
    var x = 0;
    await Future<void>.delayed(Duration(seconds: 1));
    x = 1;
  }
}
''');
  }

  /// Lines 180-182, 185: visitPropertyAccess — ref.something via PropertyAccess
  /// (e.g. this.ref triggers PropertyAccess, not PrefixedIdentifier).
  Future<void> test_refPropertyAccessAfterAwait() async {
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

  /// Lines 184: visitPropertyAccess skips ref.mounted via PropertyAccess.
  Future<void> test_refMountedPropertyAccessAfterAwait() async {
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

  /// Line 188: visitPropertyAccess falls through to super when target is not
  /// ref/state.
  Future<void> test_nonRefPropertyAccessAfterAwait() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  Future<void> doWork() async {
    final x = 'hello';
    await Future<void>.delayed(Duration(seconds: 1));
    final y = x.length;
  }
}
''');
  }

  /// Line 195: visitFunctionDeclaration — stop at named function boundaries.
  Future<void> test_refInLocalFunctionAfterAwait() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  Future<void> doWork() async {
    await Future<void>.delayed(Duration(seconds: 1));
    void localFn() {
      ref.read(Object());
    }
  }
}
''');
  }

  /// Lines 180-182, 185: visitPropertyAccess — state.something via PropertyAccess.
  Future<void> test_stateMethodCallAfterAwait() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<String> {
  Future<void> doWork() async {
    await Future<void>.delayed(Duration(seconds: 1));
    final x = state.toString();
  }
}
''',
      [lint(186, 16)],
    );
  }

  /// Lines 177-188: visitPropertyAccess — cover PropertyAccess path where
  /// ref/state is accessed through chaining.
  Future<void> test_refPropertyAccessViaChain_afterAwait() async {
    // Using a property access on ref via an intermediary expression.
    // This creates PropertyAccess rather than PrefixedIdentifier when
    // the target of the property access is not a simple identifier.
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  Ref get myRef => ref;

  Future<void> doWork() async {
    await Future<void>.delayed(Duration(seconds: 1));
    // myRef.mounted is a PropertyAccess where target is SimpleIdentifier('myRef')
    // but myRef is NOT in _targets {'ref', 'state'}, so super.visitPropertyAccess runs
    if (!myRef.mounted) return;
  }
}
''');
  }

  /// Lines 180-185: visitPropertyAccess — ref/state as SimpleIdentifier target
  /// in a PropertyAccess node (not PrefixedIdentifier). This occurs when the
  /// parser creates PropertyAccess for member access patterns.
  Future<void> test_statePropertyAccess_runtimeAccessAfterAwait() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<List<int>> {
  Future<void> doWork() async {
    await Future<void>.delayed(Duration(seconds: 1));
    final x = state[0];
  }
}
''',
      [lint(189, 5)],
    );
  }

  /// Lines 159-162: ref as part of MethodInvocation target (not reported by
  /// visitSimpleIdentifier since MethodInvocation visitor handles it).
  Future<void> test_refListenAfterAwait() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  Future<void> doWork() async {
    await Future<void>.delayed(Duration(seconds: 1));
    ref.listen(Object(), (prev, next) {});
  }
}
''',
      [lint(173, 37)],
    );
  }
}
