import 'package:many_lints/src/rules/prefer_task_either_over_try_catch.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fpdart_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferTaskEitherOverTryCatchTest),
  );
}

@reflectiveTest
class PreferTaskEitherOverTryCatchTest extends FpdartRuleTest {
  @override
  void setUp() {
    rule = PreferTaskEitherOverTryCatch();
    super.setUp();
  }

  Future<void> test_repositoryWithTryCatch() async {
    await assertDiagnostics(
      r'''
class UserRepository {
  Future<String> load(String id) async {
    try {
      return id;
    } catch (e) {
      rethrow;
    }
  }
}
''',
      [lint(40, 4)],
    );
  }

  Future<void> test_serviceWithTryCatch() async {
    await assertDiagnostics(
      r'''
class AuthService {
  Future<String> signIn() async {
    try {
      return 'token';
    } catch (e) {
      rethrow;
    }
  }
}
''',
      [lint(37, 6)],
    );
  }

  Future<void> test_taskEitherIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

class UserRepository {
  TaskEither<String, String> load(String id) => TaskEither.of(id);
}
''');
  }

  Future<void> test_nonBoundaryClassIsFine() async {
    await assertNoDiagnostics(r'''
class Helper {
  Future<String> load(String id) async {
    try {
      return id;
    } catch (e) {
      rethrow;
    }
  }
}
''');
  }

  Future<void> test_privateMethodIsFineByDefault() async {
    await assertNoDiagnostics(r'''
class UserRepository {
  Future<String> _load(String id) async {
    try {
      return id;
    } catch (e) {
      rethrow;
    }
  }
}
''');
  }

  Future<void> test_privateMethodReportedWhenConfigured() async {
    newFile('$testPackageRootPath/many_lints.yaml', '''
rules:
  prefer_task_either_over_try_catch:
    ignore_private: false
''');

    await assertDiagnostics(
      r'''
class UserRepository {
  Future<String> _load(String id) async {
    try {
      return id;
    } catch (e) {
      rethrow;
    }
  }
}
''',
      [lint(40, 5)],
    );
  }

  Future<void> test_additionalSuffixReported() async {
    newFile('$testPackageRootPath/many_lints.yaml', '''
rules:
  prefer_task_either_over_try_catch:
    additional_class_suffixes:
      - Gateway
''');

    await assertDiagnostics(
      r'''
class PaymentGateway {
  Future<String> charge() async {
    try {
      return 'ok';
    } catch (e) {
      rethrow;
    }
  }
}
''',
      [lint(40, 6)],
    );
  }

  Future<void> test_syncMethodIsFine() async {
    // A synchronous failable method is Either's job, not TaskEither's.
    await assertNoDiagnostics(r'''
class UserRepository {
  String load(String id) {
    try {
      return id;
    } catch (e) {
      rethrow;
    }
  }
}
''');
  }

  Future<void> test_tryFinallyIsFine() async {
    // Cleanup, not failure handling — TaskEither does not replace it.
    await assertNoDiagnostics(r'''
class UserRepository {
  Future<String> load(String id) async {
    try {
      return id;
    } finally {
      print('done');
    }
  }
}
''');
  }

  Future<void> test_tryInsideClosureIsFine() async {
    await assertNoDiagnostics(r'''
class UserRepository {
  Future<String> load(String id) async {
    final best = () {
      try {
        return id;
      } catch (e) {
        return '';
      }
    };
    return best();
  }
}
''');
  }
}
