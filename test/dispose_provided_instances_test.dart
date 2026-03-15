import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/dispose_provided_instances.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(DisposeProvidedInstancesTest),
  );
}

@reflectiveTest
class DisposeProvidedInstancesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = DisposeProvidedInstances();

    final riverpod = newPackage('riverpod');
    riverpod.addFile('lib/riverpod.dart', r'''
class Ref {
  T read<T>(Object provider) => throw '';
  T watch<T>(Object provider) => throw '';
  void listen(Object provider, void Function(dynamic, dynamic) listener) {}
  void onDispose(void Function() callback) {}
}

class Provider<T> {
  Provider(T Function(Ref ref) create);
  Provider.autoDispose(T Function(Ref ref) create);
}

class StateProvider<T> {
  StateProvider(T Function(Ref ref) create);
}

class FutureProvider<T> {
  FutureProvider(Future<T> Function(Ref ref) create);
}

class StreamProvider<T> {
  StreamProvider(Stream<T> Function(Ref ref) create);
}

class StateNotifierProvider<T, S> {
  StateNotifierProvider(T Function(Ref ref) create);
}

class ChangeNotifierProvider<T> {
  ChangeNotifierProvider(T Function(Ref ref) create);
}

class AutoDisposeProvider<T> {
  AutoDisposeProvider(T Function(Ref ref) create);
}

class AutoDisposeStateProvider<T> {
  AutoDisposeStateProvider(T Function(Ref ref) create);
}

class AutoDisposeStateNotifierProvider<T, S> {
  AutoDisposeStateNotifierProvider(T Function(Ref ref) create);
}

class AutoDisposeFutureProvider<T> {
  AutoDisposeFutureProvider(Future<T> Function(Ref ref) create);
}

class AutoDisposeStreamProvider<T> {
  AutoDisposeStreamProvider(Stream<T> Function(Ref ref) create);
}

class NotifierProvider<T extends Notifier<S>, S> {
  NotifierProvider(T Function() create);
}

class AutoDisposeNotifierProvider<T extends Notifier<S>, S> {
  AutoDisposeNotifierProvider(T Function() create);
}

class AsyncNotifierProvider<T extends AsyncNotifier<S>, S> {
  AsyncNotifierProvider(T Function() create);
}

class AutoDisposeAsyncNotifierProvider<T extends AsyncNotifier<S>, S> {
  AutoDisposeAsyncNotifierProvider(T Function() create);
}

class AutoDisposeChangeNotifierProvider<T> {
  AutoDisposeChangeNotifierProvider(T Function(Ref ref) create);
}

abstract class Notifier<State> {
  Ref get ref => throw UnimplementedError();
  State get state => throw UnimplementedError();
  set state(State value) {}
  State build();
}

abstract class AsyncNotifier<State> {
  Ref get ref => throw UnimplementedError();
  State get state => throw UnimplementedError();
  set state(State value) {}
  Future<State> build();
}

class ProviderFactory {
  static Provider<T> create<T>(T Function(Ref ref) fn) => Provider<T>(fn);
}
''');

    super.setUp();
  }

  // --- Positive cases: should trigger lint ---

  Future<void> test_providerWithDisposableInstance() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
}

final provider = Provider<DisposableService>((ref) {
  final instance = DisposableService();
  return instance;
});
''',
      [lint(152, 8)],
    );
  }

  Future<void> test_providerAutoDisposeWithDisposableInstance() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class CloseableService {
  void close() {}
}

final provider = Provider.autoDispose((ref) {
  final service = CloseableService();
  return service;
});
''',
      [lint(142, 7)],
    );
  }

  Future<void> test_providerWithCancellableInstance() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class CancellableTask {
  void cancel() {}
}

final provider = Provider<CancellableTask>((ref) {
  final task = CancellableTask();
  return task;
});
''',
      [lint(147, 4)],
    );
  }

  Future<void> test_notifierBuildWithDisposableInstance() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
}

class MyNotifier extends Notifier<DisposableService> {
  @override
  DisposableService build() {
    final instance = DisposableService();
    return instance;
  }
}
''',
      [lint(198, 8)],
    );
  }

  Future<void> test_asyncNotifierBuildWithDisposableInstance() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
}

class MyAsyncNotifier extends AsyncNotifier<DisposableService> {
  @override
  Future<DisposableService> build() async {
    final instance = DisposableService();
    return instance;
  }
}
''',
      [lint(222, 8)],
    );
  }

  Future<void> test_multipleDisposableInstances() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class DisposableA {
  void dispose() {}
}

class DisposableB {
  void close() {}
}

final provider = Provider<DisposableA>((ref) {
  final a = DisposableA();
  final b = DisposableB();
  return a;
});
''',
      [lint(181, 1), lint(208, 1)],
    );
  }

  // --- Negative cases: should NOT trigger lint ---

  Future<void> test_providerWithOnDisposeTearOff() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
}

final provider = Provider<DisposableService>((ref) {
  final instance = DisposableService();
  ref.onDispose(instance.dispose);
  return instance;
});
''');
  }

  Future<void> test_providerWithOnDisposeLambda() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
}

final provider = Provider<DisposableService>((ref) {
  final instance = DisposableService();
  ref.onDispose(() => instance.dispose());
  return instance;
});
''');
  }

  Future<void> test_providerWithOnDisposeBlock() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
}

final provider = Provider<DisposableService>((ref) {
  final instance = DisposableService();
  ref.onDispose(() {
    instance.dispose();
  });
  return instance;
});
''');
  }

  Future<void> test_providerWithOnDisposeClose() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class CloseableService {
  void close() {}
}

final provider = Provider<CloseableService>((ref) {
  final service = CloseableService();
  ref.onDispose(service.close);
  return service;
});
''');
  }

  Future<void> test_providerWithNonDisposableInstance() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class RegularService {
  void doSomething() {}
}

final provider = Provider<RegularService>((ref) {
  final instance = RegularService();
  return instance;
});
''');
  }

  Future<void> test_notifierBuildWithOnDispose() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
}

class MyNotifier extends Notifier<DisposableService> {
  @override
  DisposableService build() {
    final instance = DisposableService();
    ref.onDispose(instance.dispose);
    return instance;
  }
}
''');
  }

  Future<void> test_nonProviderFunction() async {
    await assertNoDiagnostics(r'''
class DisposableService {
  void dispose() {}
}

DisposableService createService() {
  final instance = DisposableService();
  return instance;
}
''');
  }

  Future<void> test_providerWithOneDisposedOneMissing() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class DisposableA {
  void dispose() {}
}

class DisposableB {
  void close() {}
}

final provider = Provider<DisposableA>((ref) {
  final a = DisposableA();
  final b = DisposableB();
  ref.onDispose(a.dispose);
  return a;
});
''',
      [lint(208, 1)],
    );
  }

  // --- Additional provider type tests ---

  Future<void> test_stateProviderWithDisposableInstance() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
}

final provider = StateProvider<DisposableService>((ref) {
  final instance = DisposableService();
  return instance;
});
''',
      [lint(157, 8)],
    );
  }

  Future<void> test_futureProviderWithDisposableInstance() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
}

final provider = FutureProvider<DisposableService>((ref) async {
  final instance = DisposableService();
  return instance;
});
''',
      [lint(164, 8)],
    );
  }

  Future<void> test_streamProviderWithDisposableInstance() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
}

final provider = StreamProvider<DisposableService>((ref) async* {
  final instance = DisposableService();
  yield instance;
});
''',
      [lint(165, 8)],
    );
  }

  Future<void> test_stateNotifierProviderWithDisposableInstance() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class DisposableNotifier {
  void dispose() {}
}

final provider = StateNotifierProvider<DisposableNotifier, int>((ref) {
  final instance = DisposableNotifier();
  return instance;
});
''',
      [lint(172, 8)],
    );
  }

  Future<void> test_changeNotifierProviderWithDisposableInstance() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class DisposableNotifier {
  void dispose() {}
}

final provider = ChangeNotifierProvider<DisposableNotifier>((ref) {
  final instance = DisposableNotifier();
  return instance;
});
''',
      [lint(168, 8)],
    );
  }

  Future<void> test_autoDisposeProviderWithDisposableInstance() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
}

final provider = AutoDisposeProvider<DisposableService>((ref) {
  final instance = DisposableService();
  return instance;
});
''',
      [lint(163, 8)],
    );
  }

  Future<void> test_autoDisposeStateProviderWithDisposableInstance() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
}

final provider = AutoDisposeStateProvider<DisposableService>((ref) {
  final instance = DisposableService();
  return instance;
});
''',
      [lint(168, 8)],
    );
  }

  Future<void>
  test_autoDisposeStateNotifierProviderWithDisposableInstance() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class DisposableNotifier {
  void dispose() {}
}

final provider = AutoDisposeStateNotifierProvider<DisposableNotifier, int>((ref) {
  final instance = DisposableNotifier();
  return instance;
});
''',
      [lint(183, 8)],
    );
  }

  Future<void> test_autoDisposeFutureProviderWithDisposableInstance() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
}

final provider = AutoDisposeFutureProvider<DisposableService>((ref) async {
  final instance = DisposableService();
  return instance;
});
''',
      [lint(175, 8)],
    );
  }

  Future<void> test_autoDisposeStreamProviderWithDisposableInstance() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
}

final provider = AutoDisposeStreamProvider<DisposableService>((ref) async* {
  final instance = DisposableService();
  yield instance;
});
''',
      [lint(176, 8)],
    );
  }

  Future<void>
  test_autoDisposeChangeNotifierProviderWithDisposableInstance() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class DisposableNotifier {
  void dispose() {}
}

final provider = AutoDisposeChangeNotifierProvider<DisposableNotifier>((ref) {
  final instance = DisposableNotifier();
  return instance;
});
''',
      [lint(179, 8)],
    );
  }

  Future<void> test_stateProviderWithOnDispose() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
}

final provider = StateProvider<DisposableService>((ref) {
  final instance = DisposableService();
  ref.onDispose(instance.dispose);
  return instance;
});
''');
  }

  // --- Cover MethodInvocation provider construction (lines 74-77) ---

  Future<void> test_providerWithoutTypeArgsTriggersLint() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
}

final provider = Provider((ref) {
  final instance = DisposableService();
  return instance;
});
''',
      [lint(133, 8)],
    );
  }

  // --- Cover PropertyAccess in onDispose (lines 254-258) ---
  // This covers the PropertyAccess path where ref.onDispose(expr.dispose)
  // is parsed as PropertyAccess rather than PrefixedIdentifier

  Future<void> test_providerOnDisposeWithPropertyAccessTearOff() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
}

class Holder {
  DisposableService instance = DisposableService();
}

final provider = Provider<int>((ref) {
  final holder = Holder();
  ref.onDispose(holder.instance.dispose);
  return 0;
});
''');
  }

  // --- Cover FunctionDeclaration boundary stop (line 214) ---

  Future<void> test_disposableInsideNestedFunctionNotReported() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
}

final provider = Provider<int>((ref) {
  void helperFunction() {
    final inner = DisposableService();
  }
  return 42;
});
''');
  }

  // --- Cover null type in variable finder (line 193) ---

  Future<void> test_providerWithVarKeyword() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

final provider = Provider<int>((ref) {
  var x = 42;
  return x;
});
''');
  }

  // --- Cover visitMethodInvocation with non-provider type (line 74 early return) ---

  Future<void> test_methodInvocation_nonProvider_noLint() async {
    await assertNoDiagnostics(r'''
class DisposableService {
  void dispose() {}
}

class NotAProvider {
  static NotAProvider call(void Function() fn) => NotAProvider();
}

void f() {
  NotAProvider.call(() {
    final instance = DisposableService();
  });
}
''');
  }

  // --- Cover visitMethodInvocation callback null (line 76 early return) ---

  Future<void> test_methodInvocation_providerWithNonFunctionArg_noLint() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
}

DisposableService createService(Ref ref) {
  final instance = DisposableService();
  return instance;
}

final provider = Provider(createService);
''',
      // The lint should NOT fire because callback is not a FunctionExpression
      [],
    );
  }

  // --- Cover PropertyAccess in onDispose with SimpleIdentifier target (lines 256-258) ---

  Future<void> test_providerOnDisposePropertyAccessSimpleIdentifier() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
}

class ServiceWrapper {
  DisposableService get service => DisposableService();
  void dispose() {}
}

final provider = Provider<int>((ref) {
  final wrapper = ServiceWrapper();
  ref.onDispose(wrapper.dispose);
  return 0;
});
''');
  }

  // --- Cover null type in variable declaration (line 192-193) ---

  Future<void> test_providerVariableWithNullType() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

final provider = Provider<int>((ref) {
  var x;
  x = 42;
  return x;
});
''');
  }

  // --- Cover visitMethodInvocation for Provider construction (lines 75,77) ---

  Future<void> test_providerViaStaticFactory_disposableMissing() async {
    // ProviderFactory.create<T>(fn) returns Provider<T> via static method —
    // parsed as MethodInvocation with Provider<T> staticType
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
}

final provider = ProviderFactory.create<DisposableService>((ref) {
  final instance = DisposableService();
  return instance;
});
''',
      [lint(166, 8)],
    );
  }

  Future<void> test_providerViaStaticFactory_disposableWithOnDispose() async {
    // Same factory path but with proper disposal — should not lint
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
}

final provider = ProviderFactory.create<DisposableService>((ref) {
  final instance = DisposableService();
  ref.onDispose(instance.dispose);
  return instance;
});
''');
  }

  Future<void> test_providerViaStaticFactory_nonFunctionArg() async {
    // ProviderFactory.create with a function reference (not FunctionExpression)
    // exercises line 76 (callback == null early return)
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
}

DisposableService createService(Ref ref) {
  final instance = DisposableService();
  return instance;
}

final provider = ProviderFactory.create<DisposableService>(createService);
''');
  }

  // --- Cover PropertyAccess in _OnDisposeCollector via chained access (lines 257-258) ---
  // Lines 257-258 handle PropertyAccess where target is SimpleIdentifier.
  // In practice, Dart parses `identifier.identifier` as PrefixedIdentifier,
  // and PropertyAccess is used for `expr.identifier` where expr is not a
  // simple identifier. Getting PropertyAccess with a SimpleIdentifier target
  // is an edge case the analyzer rarely produces — this is defensive code.
}
