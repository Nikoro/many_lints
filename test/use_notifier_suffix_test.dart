import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/use_notifier_suffix.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(UseNotifierSuffixTest));
}

@reflectiveTest
class UseNotifierSuffixTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = UseNotifierSuffix();
    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
class Notifier<State> {}
''');
    super.setUp();
  }

  Future<void> test_missingNotifierSuffix() async {
    await assertDiagnostics(
      r'''
import 'package:riverpod/riverpod.dart';
class Counter extends Notifier<int> {}
''',
      [lint(47, 7)],
    );
  }

  Future<void> test_hasNotifierSuffix() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';
class CounterNotifier extends Notifier<int> {}
''');
  }

  Future<void> test_notANotifier() async {
    await assertNoDiagnostics(r'''
class Counter {}
''');
  }
}
