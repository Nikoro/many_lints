import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/avoid_unmodified_loop_condition.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidUnmodifiedLoopConditionTest),
  );
}

@reflectiveTest
class AvoidUnmodifiedLoopConditionTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidUnmodifiedLoopCondition();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_counterNeverAdvanced() async {
    await assertDiagnostics(
      r'''
void f(int limit) {
  var i = 0;
  while (i < limit) {
    print(i);
  }
}
''',
      [lint(42, 9)],
    );
  }

  Future<void> test_wrongVariableAdvanced() async {
    await assertDiagnostics(
      r'''
void f(int limit) {
  var i = 0;
  var j = 0;
  while (i < limit) {
    j++;
  }
}
''',
      [lint(55, 9)],
    );
  }

  Future<void> test_doWhileNeverAdvanced() async {
    await assertDiagnostics(
      r'''
void f(int limit) {
  var i = 0;
  do {
    print(i);
  } while (i < limit);
}
''',
      [lint(65, 9)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_counterAdvanced() async {
    await assertNoDiagnostics(r'''
void f(int limit) {
  var i = 0;
  while (i < limit) {
    i++;
  }
}
''');
  }

  Future<void> test_compoundAssignment() async {
    await assertNoDiagnostics(r'''
void f(int limit) {
  var i = 0;
  while (i < limit) {
    i += 2;
  }
}
''');
  }

  Future<void> test_whileTrueIsIdiomatic() async {
    await assertNoDiagnostics(r'''
void f(List<int> items) {
  while (true) {
    if (items.isEmpty) break;
    items.removeLast();
  }
}
''');
  }

  Future<void> test_breakEscapes() async {
    await assertNoDiagnostics(r'''
void f(int limit) {
  var i = 0;
  while (i < limit) {
    break;
  }
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_methodCallConditionIsOpaque() async {
    await assertNoDiagnostics(r'''
void f(List<int> items) {
  while (items.isNotEmpty) {
    print(items);
  }
}
''');
  }

  Future<void> test_fieldConditionIsOpaque() async {
    await assertNoDiagnostics(r'''
class Runner {
  bool running = true;

  void go() {
    while (running) {
      print('working');
    }
  }
}
''');
  }

  Future<void> test_closurePresenceIsIgnored() async {
    await assertNoDiagnostics(r'''
void f(int limit, void Function(void Function()) run) {
  var i = 0;
  while (i < limit) {
    run(() {
      i++;
    });
  }
}
''');
  }
}
