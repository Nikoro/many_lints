import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_duplicate_collection_elements.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidDuplicateCollectionElementsTest),
  );
}

@reflectiveTest
class AvoidDuplicateCollectionElementsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidDuplicateCollectionElements();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_duplicateInListLiteral() async {
    await assertDiagnostics(
      r'''
final values = [1, 2, 1];
''',
      [lint(22, 1)],
    );
  }

  Future<void> test_duplicateStringInList() async {
    await assertDiagnostics(
      r'''
final names = ['a', 'b', 'a'];
''',
      [lint(25, 3)],
    );
  }

  Future<void> test_duplicateConstReference() async {
    await assertDiagnostics(
      r'''
const limit = 10;

final values = [limit, 20, limit];
''',
      [lint(46, 5)],
    );
  }

  Future<void> test_duplicateEnumConstant() async {
    await assertDiagnostics(
      r'''
enum Status { active, inactive }

final values = [Status.active, Status.inactive, Status.active];
''',
      [lint(82, 13)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_noDuplicates() async {
    await assertNoDiagnostics(r'''
final values = [1, 2, 3];
''');
  }

  Future<void> test_setLiteralIsCoveredBySdk() async {
    await assertNoDiagnostics(r'''
final values = <int>{1, 2, 3};
''');
  }

  Future<void> test_mapWithDuplicateValues() async {
    await assertNoDiagnostics(r'''
final labels = {'a': 1, 'b': 1};
''');
  }

  Future<void> test_repeatedMethodCalls() async {
    await assertNoDiagnostics(r'''
int next() => 0;

final values = [next(), next()];
''');
  }

  Future<void> test_listWithSpread() async {
    await assertNoDiagnostics(r'''
final base = [1, 2];
final values = [1, ...base, 1];
''');
  }

  Future<void> test_listWithIfElement() async {
    await assertNoDiagnostics(r'''
List<int> build(bool flag) {
  return [1, if (flag) 2, 1];
}
''');
  }

  Future<void> test_differentValues() async {
    await assertNoDiagnostics(r'''
enum Status { active, inactive }

final values = [Status.active, Status.inactive];
''');
  }
}
