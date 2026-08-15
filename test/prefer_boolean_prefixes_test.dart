import 'package:many_lints/src/rules/prefer_boolean_prefixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferBooleanPrefixesTest));
}

@reflectiveTest
class PreferBooleanPrefixesTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferBooleanPrefixes();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_fieldNamedAsAValue() async {
    await assertDiagnostics(
      r'''
class A {
  bool enabled = false;
}
''',
      [lint(17, 7)],
    );
  }

  Future<void> test_getterNamedAsAValue() async {
    await assertDiagnostics(
      r'''
class A {
  bool get admin => true;
}
''',
      [lint(21, 5)],
    );
  }

  Future<void> test_pastParticipleIsNotAQuestion() async {
    await assertDiagnostics(
      r'''
class A {
  bool emailSent = false;
}
''',
      [lint(17, 9)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_isPrefix() async {
    await assertNoDiagnostics(r'''
class A {
  bool isActive = false;
}
''');
  }

  Future<void> test_hasPrefix() async {
    await assertNoDiagnostics(r'''
class A {
  bool get hasItems => true;
}
''');
  }

  Future<void> test_canPrefix() async {
    await assertNoDiagnostics(r'''
class A {
  bool canSubmit() => true;
}
''');
  }

  Future<void> test_privateNameJudgedWithoutUnderscore() async {
    await assertNoDiagnostics(r'''
class A {
  bool _isReady = false;
}
''');
  }

  Future<void> test_nonBooleanIsIgnored() async {
    await assertNoDiagnostics(r'''
class A {
  String label = '';
  int count = 0;
}
''');
  }

  Future<void> test_overrideKeepsTheInheritedName() async {
    // Only the base declaration is reported; the override cannot rename
    // independently, so flagging it would demand an impossible fix.
    await assertDiagnostics(
      r'''
class Base {
  bool get admin => false;
}

class A extends Base {
  @override
  bool get admin => true;
}
''',
      [lint(24, 5)],
    );
  }

  Future<void> test_setterIsNamedByItsGetter() async {
    await assertNoDiagnostics(r'''
class A {
  bool _value = false;
  set enabled(bool value) => _value = value;
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_verbDoesNotHaveToLead() async {
    // `localeIsDefault` asks the same question as `isDefaultLocale`; naming
    // the subject first keeps related settings sorting together.
    await assertNoDiagnostics(r'''
class A {
  bool localeIsDefault = false;
  bool themeModeIsDefault = false;
}
''');
  }

  Future<void> test_thirdPersonVerbIsAlreadyAQuestion() async {
    await assertNoDiagnostics(r'''
class A {
  bool involves(String id) => true;
  bool matches(String id) => true;
}
''');
  }

  Future<void> test_prefixMustEndAtAWordBoundary() async {
    // `island` merely starts with `is`.
    await assertDiagnostics(
      r'''
class A {
  bool island = false;
}
''',
      [lint(17, 6)],
    );
  }
}
