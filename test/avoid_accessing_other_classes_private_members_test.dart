import 'package:many_lints/src/rules/avoid_accessing_other_classes_private_members.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidAccessingOtherClassesPrivateMembersTest),
  );
}

@reflectiveTest
class AvoidAccessingOtherClassesPrivateMembersTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidAccessingOtherClassesPrivateMembers();
    super.setUp();
  }

  // Dart scopes privacy to the LIBRARY, so this compiles — which is exactly
  // the gap between what `_` reads as and what it means.
  Future<void> test_readingAnotherClassPrivateField() async {
    await assertDiagnostics(
      r'''
class Account {
  int _balance = 0;
}

class Report {
  int total(Account account) => account._balance;
}
''',
      [lint(94, 8)],
    );
  }

  Future<void> test_ownPrivateFieldIsFine() async {
    await assertNoDiagnostics(r'''
class Account {
  int _balance = 0;

  int get balance => _balance;
  int get viaThis => this._balance;
}
''');
  }

  // Another instance of the SAME class is the `==` / `copyWith` pattern.
  Future<void> test_sameClassOtherInstanceIsFine() async {
    await assertNoDiagnostics(r'''
class Account {
  int _balance = 0;

  bool sameAs(Account other) => _balance == other._balance;
}
''');
  }

  Future<void> test_publicMemberIsFine() async {
    await assertNoDiagnostics(r'''
class Account {
  int balance = 0;
}

class Report {
  int total(Account account) => account.balance;
}
''');
  }

  // `copyWith` exists precisely to read another instance's fields.
  Future<void> test_ignoredMemberIsExempt() async {
    await assertNoDiagnostics(r'''
class Account {
  int _balance = 0;
}

class Report {
  Account? source;

  Report copyWith(Account account) {
    print(account._balance);
    return this;
  }
}
''');
  }
}
