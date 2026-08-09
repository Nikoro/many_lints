import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_unremovable_callbacks_in_listeners.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidUnremovableCallbacksInListenersTest),
  );
}

@reflectiveTest
class AvoidUnremovableCallbacksInListenersTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnremovableCallbacksInListeners();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_inlineClosure() async {
    await assertDiagnostics(
      r'''
class Controller {
  void addListener(void Function() listener) {}
}

void f(Controller controller) {
  controller.addListener(() {
    print('changed');
  });
}
''',
      [lint(127, 30)],
    );
  }

  Future<void> test_arrowClosure() async {
    await assertDiagnostics(
      r'''
class Controller {
  void addListener(void Function() listener) {}
}

void f(Controller controller) {
  controller.addListener(() => print('changed'));
}
''',
      [lint(127, 22)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_methodTearOff() async {
    await assertNoDiagnostics(r'''
class Controller {
  void addListener(void Function() listener) {}
}

class Widget {
  final Controller controller = Controller();

  void _onChange() {}

  void start() {
    controller.addListener(_onChange);
  }
}
''');
  }

  Future<void> test_fieldReference() async {
    await assertNoDiagnostics(r'''
class Controller {
  void addListener(void Function() listener) {}
}

void f(Controller controller, void Function() listener) {
  controller.addListener(listener);
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_unrelatedMethodIsIgnored() async {
    await assertNoDiagnostics(r'''
class Runner {
  void run(void Function() task) {}
}

void f(Runner runner) {
  runner.run(() {
    print('go');
  });
}
''');
  }

  Future<void> test_addStatusListenerIsCovered() async {
    await assertDiagnostics(
      r'''
class Animation {
  void addStatusListener(void Function() listener) {}
}

void f(Animation animation) {
  animation.addStatusListener(() {
    print('status');
  });
}
''',
      [lint(135, 29)],
    );
  }
}
