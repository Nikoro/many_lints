import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_unassigned_stream_subscriptions.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidUnassignedStreamSubscriptionsTest),
  );
}

@reflectiveTest
class AvoidUnassignedStreamSubscriptionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnassignedStreamSubscriptions();
    super.setUp();
  }

  Future<void> test_unassignedListen() async {
    await assertDiagnostics(
      r'''
import 'dart:async';

void fn() {
  final stream = Stream.fromIterable([1, 2, 3]);
  stream.listen((event) {});
}
''',
      [lint(85, 25)],
    );
  }

  Future<void> test_unassignedListenWithCallbacks() async {
    await assertDiagnostics(
      r'''
import 'dart:async';

void fn() {
  final stream = Stream.fromIterable([1, 2, 3]);
  stream.listen((event) {}, onError: (e) {}, onDone: () {});
}
''',
      [lint(85, 57)],
    );
  }

  Future<void> test_assignedToVariable() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void fn() {
  final stream = Stream.fromIterable([1, 2, 3]);
  final subscription = stream.listen((event) {});
  subscription.cancel();
}
''');
  }

  Future<void> test_returnedFromFunction() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

StreamSubscription<int> fn() {
  final stream = Stream.fromIterable([1, 2, 3]);
  return stream.listen((event) {});
}
''');
  }

  Future<void> test_passedAsArgument() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void addSub(StreamSubscription sub) {}

void fn() {
  final stream = Stream.fromIterable([1, 2, 3]);
  addSub(stream.listen((event) {}));
}
''');
  }

  Future<void> test_nonStreamListenMethod() async {
    await assertNoDiagnostics(r'''
class MyClass {
  void listen(void Function(int) callback) {}
}

void fn() {
  final obj = MyClass();
  obj.listen((event) {});
}
''');
  }

  Future<void> test_usedInAwait() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

Future<void> fn() async {
  final stream = Stream.fromIterable([1, 2, 3]);
  await stream.listen((event) {}).asFuture();
}
''');
  }
}
