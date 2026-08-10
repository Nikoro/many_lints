import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/function_always_returns_null.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(FunctionAlwaysReturnsNullTest),
  );
}

@reflectiveTest
class FunctionAlwaysReturnsNullTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = FunctionAlwaysReturnsNull();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_everyPathReturnsNull() async {
    await assertDiagnostics(
      r'''
String? lookup(String key) {
  if (key.isEmpty) return null;
  return null;
}
''',
      [lint(8, 6)],
    );
  }

  Future<void> test_expressionBodyReturnsNull() async {
    await assertDiagnostics(
      r'''
String? lookup(String key) => null;
''',
      [lint(8, 6)],
    );
  }

  Future<void> test_methodReturnsNull() async {
    await assertDiagnostics(
      r'''
class Repository {
  String? find(String key) {
    return null;
  }
}
''',
      [lint(29, 4)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_someBranchReturnsValue() async {
    await assertNoDiagnostics(r'''
String? lookup(String key) {
  if (key.isEmpty) return null;
  return key;
}
''');
  }

  Future<void> test_nonNullableReturn() async {
    await assertNoDiagnostics(r'''
String lookup(String key) => key;
''');
  }

  Future<void> test_voidFunction() async {
    await assertNoDiagnostics(r'''
void run() {
  return;
}
''');
  }

  Future<void> test_overrideIsIgnored() async {
    await assertNoDiagnostics(r'''
class Base {
  String? find(String key) => key;
}

class Child extends Base {
  @override
  String? find(String key) => null;
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_asyncBodyIsIgnored() async {
    await assertNoDiagnostics(r'''
Future<String?> lookup(String key) async {
  return null;
}
''');
  }

  Future<void> test_closureReturnIsNotAttributedToOuter() async {
    await assertNoDiagnostics(r'''
String? lookup(String key) {
  final inner = () => null;
  inner();
  return key;
}
''');
  }

  Future<void> test_noReturnAtAllIsIgnored() async {
    await assertNoDiagnostics(r'''
String? lookup(String key) {
  print(key);
  return key;
}
''');
  }
}
