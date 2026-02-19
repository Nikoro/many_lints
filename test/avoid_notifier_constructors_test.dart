import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_notifier_constructors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidNotifierConstructorsTest),
  );
}

@reflectiveTest
class AvoidNotifierConstructorsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNotifierConstructors();

    final riverpod = newPackage('riverpod');
    riverpod.addFile('lib/riverpod.dart', r'''
abstract class Notifier<State> {
  State get state => throw UnimplementedError();
  set state(State value) {}
  State build();
}

abstract class AsyncNotifier<State> {
  State get state => throw UnimplementedError();
  set state(State value) {}
  Future<State> build();
}
''');

    super.setUp();
  }

  // --- Positive cases: should trigger lint ---

  Future<void> test_notifierConstructorWithBody() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class Counter extends Notifier<int> {
  var _initial = 0;

  Counter() {
    _initial = 1;
  }

  @override
  int build() => _initial;
}
''',
      [lint(103, 33)],
    );
  }

  Future<void> test_notifierConstructorWithInitializerList() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class Counter extends Notifier<int> {
  final int _initial;

  Counter() : _initial = 1;

  @override
  int build() => _initial;
}
''',
      [lint(105, 25)],
    );
  }

  Future<void> test_asyncNotifierConstructorWithBody() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class Counter extends AsyncNotifier<int> {
  var _initial = 0;

  Counter() {
    _initial = 1;
  }

  @override
  Future<int> build() async => _initial;
}
''',
      [lint(108, 33)],
    );
  }

  Future<void> test_namedConstructorWithBody() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class Counter extends Notifier<int> {
  var _initial = 0;

  Counter.custom() {
    _initial = 1;
  }

  @override
  int build() => _initial;
}
''',
      [lint(103, 40)],
    );
  }

  Future<void> test_constructorWithMultipleInitializers() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';

class Counter extends Notifier<int> {
  final int _a;
  final int _b;

  Counter() : _a = 1, _b = 2;

  @override
  int build() => _a + _b;
}
''',
      [lint(115, 27)],
    );
  }

  // --- Negative cases: should NOT trigger lint ---

  Future<void> test_noConstructor() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class Counter extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
}
''');
  }

  Future<void> test_emptyConstructor() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class Counter extends Notifier<int> {
  Counter();

  @override
  int build() => 0;
}
''');
  }

  Future<void> test_constructorWithEmptyBody() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class Counter extends Notifier<int> {
  Counter() {}

  @override
  int build() => 0;
}
''');
  }

  Future<void> test_constructorWithSuperOnly() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class Counter extends Notifier<int> {
  Counter() : super();

  @override
  int build() => 0;
}
''');
  }

  Future<void> test_notANotifierClass() async {
    await assertNoDiagnostics(r'''
class NotANotifier {
  late String _data;

  NotANotifier() {
    _data = 'Hello';
  }
}
''');
  }
}
