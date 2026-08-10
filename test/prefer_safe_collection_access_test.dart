import 'package:many_lints/src/rules/prefer_safe_collection_access.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fpdart_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferSafeCollectionAccessTest),
  );
}

@reflectiveTest
class PreferSafeCollectionAccessTest extends FpdartRuleTest {
  @override
  void setUp() {
    rule = PreferSafeCollectionAccess();
    super.setUp();
  }

  Future<void> test_firstInsidePipeline() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

Option<int> f(List<int> values) => Option.of(values.first);
''',
      [lint(90, 5)],
    );
  }

  Future<void> test_lastInsidePipeline() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> f(List<int> values) =>
    TaskEither.of(values.last);
''',
      [lint(110, 4)],
    );
  }

  Future<void> test_propertyAccessReceiver() async {
    await assertDiagnostics(
      r'''
import 'package:fpdart/fpdart.dart';

class Team {
  List<int> scores = [];
}

Option<int> f(Team team) => Option.of(team.scores.first);
''',
      [lint(129, 5)],
    );
  }

  Future<void> test_safeAccessorIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<int> f(List<int> values) => values.head;
''');
  }

  Future<void> test_outsidePipelineIsFineByDefault() async {
    await assertNoDiagnostics(r'''
int f(List<int> values) => values.first;
''');
  }

  Future<void> test_outsidePipelineReportedWhenConfigured() async {
    newFile('$testPackageRootPath/many_lints.yaml', '''
preset: all
rules:
  prefer_safe_collection_access:
    report_outside_pipelines: true
''');

    await assertDiagnostics(
      r'''
int f(List<int> values) => values.first;
''',
      [lint(34, 5)],
    );
  }

  Future<void> test_accessorsOptionNarrows() async {
    newFile('$testPackageRootPath/many_lints.yaml', '''
preset: all
rules:
  prefer_safe_collection_access:
    accessors:
      - single
''');

    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

Option<int> f(List<int> values) => Option.of(values.first);
''');
  }

  Future<void> test_nonCollectionPropertyIsFine() async {
    await assertNoDiagnostics(r'''
import 'package:fpdart/fpdart.dart';

class Record {
  int first = 0;
}

Option<int> f(Record record) => Option.of(record.first);
''');
  }
}
