import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/protected_notifier_properties.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(ProtectedNotifierPropertiesTest),
  );
}

@reflectiveTest
class ProtectedNotifierPropertiesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = ProtectedNotifierProperties();

    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
class Ref {}

abstract class Notifier<State> {
  State get state => throw UnimplementedError();
  set state(State value) {}
  Ref get ref => throw UnimplementedError();
  State build();
}

abstract class AsyncNotifier<State> {
  State get state => throw UnimplementedError();
  set state(State value) {}
  State? get stateOrNull => throw UnimplementedError();
  Future<State> get future => throw UnimplementedError();
  Ref get ref => throw UnimplementedError();
  Future<State> build();
}
''');

    super.setUp();
  }

  // --- Positive cases: should trigger lint ---

  Future<void> test_stateAccessedFromOutside() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  @override
  int build() => 0;
}

void fn(MyNotifier notifier) {
  print(notifier.state);
}
''',
      [lint(166, 5)],
    );
  }

  Future<void> test_stateAssignedFromOutside() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  @override
  int build() => 0;
}

void fn(MyNotifier notifier) {
  notifier.state = 1;
}
''',
      [lint(160, 5)],
    );
  }

  Future<void> test_refAccessedFromOutside() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  @override
  int build() => 0;
}

void fn(MyNotifier notifier) {
  print(notifier.ref);
}
''',
      [lint(166, 3)],
    );
  }

  Future<void> test_futureAndStateOrNullAccessedFromOutside() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async => 0;
}

void fn(MyNotifier notifier) {
  print(notifier.future);
  print(notifier.stateOrNull);
}
''',
      [lint(185, 6), lint(211, 11)],
    );
  }

  Future<void> test_accessedFromAnotherNotifier() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class OtherNotifier extends Notifier<int> {
  @override
  int build() => 0;
}

class MyNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void peek(OtherNotifier other) {
    print(other.state);
  }
}
''',
      [lint(246, 5)],
    );
  }

  // --- Negative cases: should not trigger lint ---

  Future<void> test_stateUsedInsideOwnNotifier() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() {
    state = state + 1;
    print(ref);
  }
}
''');
  }

  Future<void> test_sameProperiesOnNonNotifierNotFlagged() async {
    await assertNoDiagnostics(r'''
class NotANotifier {
  int state = 0;
  Object? ref;
}

void fn(NotANotifier value) {
  print(value.state);
  print(value.ref);
}
''');
  }

  Future<void> test_unrelatedPropertyNotFlagged() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  int get count => 0;

  @override
  int build() => 0;
}

void fn(MyNotifier notifier) {
  print(notifier.count);
}
''');
  }
}
