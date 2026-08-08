import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/use_class_prefix.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(UseClassPrefixTest));
}

/// See `use_class_suffix_test.dart` — `AnalysisRuleTest` cannot supply
/// configuration, so this suite only proves the rule is silent by default.
/// Configured behaviour lives in `rule_options_test.dart`.
@reflectiveTest
class UseClassPrefixTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = UseClassPrefix();
    newPackage('bloc').addFile('lib/bloc.dart', r'''
class Bloc<Event, State> {}
''');
    super.setUp();
  }

  Future<void> test_noConfig_noLint() async {
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
