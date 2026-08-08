import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/use_class_suffix.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(UseClassSuffixTest));
}

/// `AnalysisRuleTest` gives the rule no package root, so no `many_lints.yaml`
/// is ever read and `entries:` is always empty here. That makes this suite
/// exactly one thing: proof that the rule is silent until configured.
///
/// The configured behaviour is covered end-to-end in `rule_options_test.dart`,
/// which drives a real `PluginServer` with a config file.
@reflectiveTest
class UseClassSuffixTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = UseClassSuffix();
    newPackage('bloc').addFile('lib/bloc.dart', r'''
class Bloc<Event, State> {}
''');
    super.setUp();
  }

  Future<void> test_noConfig_noLint() async {
    // Without `entries:` the rule enforces nothing — installing the package
    // must not impose a naming convention on anyone.
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
