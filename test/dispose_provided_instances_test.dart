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
}
