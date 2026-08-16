import 'package:many_lints/src/rules/prefer_correct_identifier_length.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferCorrectIdentifierLengthTest),
  );
}

@reflectiveTest
class PreferCorrectIdentifierLengthTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferCorrectIdentifierLength();
    super.setUp();
  }

  Future<void> test_tooShort() async {
    await assertDiagnostics(
      r'''
void f() {
  final q = 1;
  print(q);
}
''',
      [lint(19, 1)],
    );
  }

  Future<void> test_tooLong() async {
    await assertDiagnostics(
      r'''
void f() {
  final theCompletelyUnnecessarilyVerboseVariableName = 1;
  print(theCompletelyUnnecessarilyVerboseVariableName);
}
''',
      [lint(19, 45)],
    );
  }

  Future<void> test_reasonableName() async {
    await assertNoDiagnostics(r'''
void f() {
  final count = 1;
  print(count);
}
''');
  }

  // The conventional short names are exempt out of the box.
  Future<void> test_loopCounterIsAllowed() async {
    await assertNoDiagnostics(r'''
void f() {
  for (var i = 0; i < 3; i++) {
    print(i);
  }
}
''');
  }

  Future<void> test_catchClauseEIsAllowed() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
    print(1);
  } catch (e) {
    print(e);
  }
}
''');
  }

  // A private name's underscore is a modifier, not part of its length.
  Future<void> test_underscoreIsNotCounted() async {
    await assertNoDiagnostics(r'''
class C {
  final int _id = 0;
}
''');
  }
}
