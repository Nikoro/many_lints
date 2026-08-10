import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/avoid_default_tostring.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidDefaultTostringTest));
}

@reflectiveTest
class AvoidDefaultTostringTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidDefaultTostring();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_interpolatedClassWithoutToString() async {
    await assertDiagnostics(
      r'''
class User {
  const User(this.id);
  final String id;
}

String describe(User user) => 'user: $user';
''',
      [lint(96, 4)],
    );
  }

  Future<void> test_interpolatedWithBraces() async {
    await assertDiagnostics(
      r'''
class User {
  const User(this.id);
  final String id;
}

String describe(User user) => 'user: ${user}';
''',
      [lint(97, 4)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_classWithToStringOverride() async {
    await assertNoDiagnostics(r'''
class User {
  const User(this.id);
  final String id;

  @override
  String toString() => 'User($id)';
}

String describe(User user) => 'user: $user';
''');
  }

  Future<void> test_inheritedToStringOverride() async {
    await assertNoDiagnostics(r'''
class Base {
  @override
  String toString() => 'Base';
}

class User extends Base {}

String describe(User user) => 'user: $user';
''');
  }

  Future<void> test_interpolatedString() async {
    await assertNoDiagnostics(r'''
String describe(String name) => 'name: $name';
''');
  }

  Future<void> test_interpolatedInt() async {
    await assertNoDiagnostics(r'''
String describe(int count) => 'count: $count';
''');
  }

  Future<void> test_interpolatedField() async {
    await assertNoDiagnostics(r'''
class User {
  const User(this.id);
  final String id;
}

String describe(User user) => 'user: ${user.id}';
''');
  }

  Future<void> test_interpolatedEnum() async {
    await assertNoDiagnostics(r'''
enum Status { active, inactive }

String describe(Status status) => 'status: $status';
''');
  }
}
