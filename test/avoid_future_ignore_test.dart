import 'package:many_lints/src/rules/avoid_future_ignore.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidFutureIgnoreTest));
}

@reflectiveTest
class AvoidFutureIgnoreTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidFutureIgnore();
    super.setUp();

    // analyzer_testing's trimmed dart:async predates Future.ignore(). Extend
    // that mock rather than weakening the rule's resolved-element check.
    final asyncPath = '$sdkRoot/lib/async/async.dart';
    final asyncSource = getFile(asyncPath).readAsStringSync();
    newFile(
      asyncPath,
      asyncSource.replaceFirst('abstract class FutureOr<T> {}', '''
extension FutureExtensions<T> on Future<T> {
  void ignore() {}
}

abstract class FutureOr<T> {}
'''),
    );
    final corePath = '$sdkRoot/lib/core/core.dart';
    final coreSource = getFile(corePath).readAsStringSync();
    newFile(
      corePath,
      coreSource.replaceFirst(
        "export 'dart:async' show Future, Stream;",
        "export 'dart:async' show Future, FutureExtensions, Stream;",
      ),
    );
  }

  Future<void> test_bareIgnore_reports() async {
    await assertDiagnostics(
      r'''
void f(Future<void> future) {
  future.ignore();
}
''',
      [lint(32, 15)],
    );
  }

  Future<void> test_ignoreInsideAsyncFunction_reports() async {
    await assertDiagnostics(
      r'''
Future<void> f(Future<void> future) async {
  future.ignore();
}
''',
      [lint(46, 15)],
    );
  }

  Future<void> test_adjacentLineComment_isExempt() async {
    await assertNoDiagnostics(r'''
void f(Future<void> future) {
  // The operation is obsolete and its failure is irrelevant.
  future.ignore();
}
''');
  }

  Future<void> test_adjacentBlockComment_isExempt() async {
    await assertNoDiagnostics(r'''
void f(Future<void> future) {
  /* Best-effort cleanup. */ future.ignore();
}
''');
  }

  Future<void> test_distantComment_doesNotExempt() async {
    await assertDiagnostics(
      r'''
void f(Future<void> future) {
  // This describes something else.

  future.ignore();
}
''',
      [lint(69, 15)],
    );
  }

  Future<void> test_customIgnoreMethod_isNotFutureIgnore() async {
    await assertNoDiagnostics(r'''
class Worker {
  void ignore() {}
}

void f(Worker worker) {
  worker.ignore();
}
''');
  }

  Future<void> test_unawaited_isAllowed() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void f(Future<void> future) {
  unawaited(future);
}
''');
  }

  Future<void> test_awaitedFuture_isAllowed() async {
    await assertNoDiagnostics(r'''
Future<void> f(Future<void> future) async {
  await future;
}
''');
  }
}
