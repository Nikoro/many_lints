import 'package:many_lints/src/rules/avoid_exit_outside_entrypoint.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidExitOutsideEntrypointTest),
  );
}

@reflectiveTest
class AvoidExitOutsideEntrypointTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidExitOutsideEntrypoint();
    super.setUp();
  }

  Future<void> test_exit_call() async {
    await assertDiagnostics(
      r'''
import 'dart:io';

void upload() {
  exit(3);
}
''',
      [lint(37, 4)],
    );
  }

  Future<void> test_exit_tear_off() async {
    await assertDiagnostics(
      r'''
import 'dart:io';

void onFailure(void Function(int) handler) {}

void upload() {
  onFailure(exit);
}
''',
      [lint(94, 4)],
    );
  }

  Future<void> test_a_same_named_method_is_not_dart_io_exit() async {
    await assertNoDiagnostics(r'''
class Terminal {
  void exit(int code) {}
}

void upload() {
  Terminal().exit(3);
}
''');
  }

  Future<void> test_a_same_named_local_function() async {
    await assertNoDiagnostics(r'''
void upload() {
  void exit(int code) {}
  exit(3);
}
''');
  }

  Future<void> test_throwing_instead() async {
    await assertNoDiagnostics(r'''
class AuthFailure implements Exception {
  const AuthFailure();
}

void upload() {
  throw const AuthFailure();
}
''');
  }
}
