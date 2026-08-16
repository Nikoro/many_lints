import 'package:many_lints/src/rules/prefer_correct_setter_parameter_name.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferCorrectSetterParameterNameTest),
  );
}

@reflectiveTest
class PreferCorrectSetterParameterNameTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = PreferCorrectSetterParameterName();
    super.setUp();
  }

  Future<void> test_unconventionalParameterName() async {
    await assertDiagnostics(
      r'''
class C {
  int _a = 0;

  set a(int newValue) => _a = newValue;
}
''',
      [lint(37, 8)],
    );
  }

  Future<void> test_conventionalName() async {
    await assertNoDiagnostics(r'''
class C {
  int _a = 0;

  set a(int value) => _a = value;
}
''');
  }

  // An override inherits its parameter name along with the signature.
  Future<void> test_overrideIsSkipped() async {
    await assertNoDiagnostics(r'''
abstract class A {
  set a(int value);
}

class C implements A {
  int _a = 0;

  @override
  set a(int newValue) => _a = newValue;
}
''');
  }

  Future<void> test_getterIsNotASetter() async {
    await assertNoDiagnostics(r'''
class C {
  int get a => 0;
}
''');
  }
}
