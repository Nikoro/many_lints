import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/use_class_suffix.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(UseClassSuffixTest));
}

@reflectiveTest
class UseClassSuffixTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = UseClassSuffix();
    newPackage('bloc').addFile('lib/bloc.dart', r'''
class Bloc<Event, State> {}
''');
    super.setUp();
  }

  Future<void> test_noConfig_imposesNoNamingConvention() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';
class Counter extends Bloc<String, int> {}
''');
  }

  Future<void> test_noConfig_unrelatedClass_noLint() async {
    await assertNoDiagnostics(r'''
class Counter {}
''');
  }
}
