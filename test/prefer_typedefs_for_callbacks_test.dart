import 'package:many_lints/src/rules/prefer_typedefs_for_callbacks.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferTypedefsForCallbacksTest),
  );
}

@reflectiveTest
class PreferTypedefsForCallbacksTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferTypedefsForCallbacks();
    super.setUp();
  }

  Future<void> test_inlineFunctionTypeWithTwoParameters() async {
    await assertDiagnostics(
      r'''
void f(void Function(String, int) callback) {}
''',
      [lint(7, 26)],
    );
  }

  Future<void> test_singleParameterIsReadable() async {
    await assertNoDiagnostics(r'''
void f(void Function(String) callback) {}
''');
  }

  Future<void> test_noParameters() async {
    await assertNoDiagnostics(r'''
void f(void Function() callback) {}
''');
  }

  Future<void> test_namedTypedefIsTheGoal() async {
    await assertNoDiagnostics(r'''
typedef Handler = void Function(String, int);

void f(Handler callback) {}
''');
  }
}
