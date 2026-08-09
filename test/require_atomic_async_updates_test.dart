import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/require_atomic_async_updates.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(RequireAtomicAsyncUpdatesTest),
  );
}

@reflectiveTest
class RequireAtomicAsyncUpdatesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = RequireAtomicAsyncUpdates();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_readThenAwaitThenWrite() async {
    await assertDiagnostics(
      r'''
class Counter {
  int _value = 0;

  Future<void> increment() async {
    final current = _value;
    await Future<void>.delayed(Duration.zero);
    _value = current + 1;
  }
}
''',
      [lint(149, 20)],
    );
  }

  Future<void> test_compoundAssignmentAfterAwait() async {
    await assertDiagnostics(
      r'''
class Counter {
  int _value = 0;

  Future<void> increment() async {
    print(_value);
    await Future<void>.delayed(Duration.zero);
    _value += 1;
  }
}
''',
      [lint(140, 11)],
    );
  }

  Future<void> test_thisQualifiedWrite() async {
    await assertDiagnostics(
      r'''
class Counter {
  int _value = 0;

  Future<void> increment() async {
    final current = this._value;
    await Future<void>.delayed(Duration.zero);
    this._value = current + 1;
  }
}
''',
      [lint(154, 25)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_readAfterAwait() async {
    await assertNoDiagnostics(r'''
class Counter {
  int _value = 0;

  Future<void> increment() async {
    await Future<void>.delayed(Duration.zero);
    _value = _value + 1;
  }
}
''');
  }

  Future<void> test_unconditionalOverwriteDoesNotDependOnStaleRead() async {
    await assertNoDiagnostics(r'''
class Loader {
  int _value = 0;

  Future<void> load() async {
    print(_value);
    await Future<void>.delayed(Duration.zero);
    _value = 42;
  }
}
''');
  }

  Future<void> test_syncMethodIsIgnored() async {
    await assertNoDiagnostics(r'''
class Counter {
  int _value = 0;

  void increment() {
    final current = _value;
    _value = current + 1;
  }
}
''');
  }

  Future<void> test_localVariableNotTrackedByDefault() async {
    await assertNoDiagnostics(r'''
Future<void> run() async {
  var total = 0;
  final current = total;
  await Future<void>.delayed(Duration.zero);
  total = current + 1;
}
''');
  }

  Future<void> test_staticFieldIsIgnored() async {
    await assertNoDiagnostics(r'''
class Counter {
  static int _value = 0;

  Future<void> increment() async {
    final current = _value;
    await Future<void>.delayed(Duration.zero);
    _value = current + 1;
  }
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_otherObjectFieldIsIgnored() async {
    await assertNoDiagnostics(r'''
class Holder {
  int value = 0;
}

class Runner {
  final Holder holder = Holder();

  Future<void> run() async {
    final current = holder.value;
    await Future<void>.delayed(Duration.zero);
    holder.value = current + 1;
  }
}
''');
  }

  Future<void> test_writeInsideClosureIsIgnored() async {
    await assertNoDiagnostics(r'''
class Counter {
  int _value = 0;

  Future<void> increment() async {
    final current = _value;
    await Future<void>.delayed(Duration.zero);
    void later() {
      _value = current + 1;
    }
    later();
  }
}
''');
  }

  Future<void> test_writeBeforeAwaitIsIgnored() async {
    await assertNoDiagnostics(r'''
class Counter {
  int _value = 0;

  Future<void> increment() async {
    final current = _value;
    _value = current + 1;
    await Future<void>.delayed(Duration.zero);
  }
}
''');
  }
}
