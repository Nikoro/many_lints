import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/use_bloc_suffix.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(UseBlocSuffixTest));
}

@reflectiveTest
class UseBlocSuffixTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = UseBlocSuffix();
    newPackage('bloc').addFile('lib/bloc.dart', r'''
class Bloc<Event, State> {}
''');
    super.setUp();
  }

  Future<void> test_missingBlocSuffix() async {
    await assertDiagnostics(
      r'''
import 'package:bloc/bloc.dart';
class Counter extends Bloc<String, int> {}
''',
      [lint(39, 7)],
    );
  }

  Future<void> test_hasBlocSuffix() async {
    await assertNoDiagnostics(r'''
import 'package:bloc/bloc.dart';
class CounterBloc extends Bloc<String, int> {}
''');
  }

  Future<void> test_notABloc() async {
    await assertNoDiagnostics(r'''
class Counter {}
''');
  }
}
