import 'package:many_lints/src/rules/prefer_correct_type_name.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferCorrectTypeNameTest));
}

@reflectiveTest
class PreferCorrectTypeNameTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferCorrectTypeName();
    super.setUp();
  }

  Future<void> test_nameTooShort() async {
    await assertDiagnostics(
      r'''
class Ab {}
''',
      [lint(6, 2)],
    );
  }

  Future<void> test_nameTooLong() async {
    await assertDiagnostics(
      r'''
class AVeryLongTypeNameThatDescribesItsEntireCallChain {}
''',
      [lint(6, 48)],
    );
  }

  Future<void> test_nameOfAcceptableLength() async {
    await assertNoDiagnostics(r'''
class UserRepository {}
''');
  }

  // The underscore is not part of the name a reader judges, so a private type
  // is measured on the bare name.
  Future<void> test_privateNameMeasuredWithoutUnderscore() async {
    await assertNoDiagnostics(r'''
class _Foo {}
''');
  }

  // Type parameters are the SDK's own convention and must stay exempt.
  Future<void> test_typeParameterIsExempt() async {
    await assertNoDiagnostics(r'''
class Box<T> {
  final T value;
  Box(this.value);
}
''');
  }

  Future<void> test_mixinAndEnumAreChecked() async {
    await assertDiagnostics(
      r'''
mixin Ab {}
enum Cd { a }
''',
      [lint(6, 2), lint(17, 2)],
    );
  }

  Future<void> test_typedefIsChecked() async {
    await assertDiagnostics(
      r'''
typedef Ab = int;
''',
      [lint(8, 2)],
    );
  }
}
