import 'package:many_lints/src/rules/prefer_typed_exceptions.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferTypedExceptionsTest));
}

@reflectiveTest
class PreferTypedExceptionsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferTypedExceptions();
    super.setUp();
  }

  Future<void> test_bare_exception() async {
    await assertDiagnostics(
      r'''
void f() {
  throw Exception('upload failed');
}
''',
      [lint(13, 32)],
    );
  }

  Future<void> test_bare_error() async {
    await assertDiagnostics(
      r'''
void f() {
  throw Error();
}
''',
      [lint(13, 13)],
    );
  }

  Future<void> test_throwing_a_string() async {
    await assertDiagnostics(
      r'''
void f() {
  throw 'upload failed';
}
''',
      [lint(13, 21)],
    );
  }

  Future<void> test_throwing_a_plain_object() async {
    await assertDiagnostics(
      r'''
class Failure {
  const Failure();
}

void f() {
  throw const Failure();
}
''',
      [lint(51, 21)],
    );
  }

  Future<void> test_custom_exception_subclass() async {
    await assertNoDiagnostics(r'''
class UploadFailure implements Exception {
  const UploadFailure(this.message);

  final String message;
}

void f() {
  throw const UploadFailure('upload failed');
}
''');
  }

  Future<void> test_custom_error_subclass() async {
    await assertNoDiagnostics(r'''
class ConfigError extends Error {}

void f() {
  throw ConfigError();
}
''');
  }

  Future<void> test_allowed_sdk_error() async {
    await assertNoDiagnostics(r'''
void f(int port) {
  throw ArgumentError('port must be positive');
}
''');
  }

  /// `Exception` is only uninformative when it *is* the type thrown; a
  /// subclass named here has its own name for a caller to catch by.
  Future<void> test_exception_subclass_from_a_mixin_application() async {
    await assertNoDiagnostics(r'''
mixin Traced {}

class UploadFailure with Traced implements Exception {}

void f() {
  throw UploadFailure();
}
''');
  }

  Future<void> test_rethrow_is_not_a_throw_expression() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
    print('x');
  } catch (e) {
    rethrow;
  }
}
''');
  }
}
