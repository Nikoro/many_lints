import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/avoid_duplicate_collection_elements.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidDuplicateCollectionElementsTest),
  );
}

@reflectiveTest
class AvoidDuplicateCollectionElementsTest extends ManyLintsRuleTest {
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

  /// A spread no longer hides duplicates that follow it.
  Future<void> test_listWithSpreadStillFindsDuplicate() async {
    await assertDiagnostics(
      r'''
final base = [1, 2];
final values = [1, ...base, 1];
''',
      [lint(49, 1)],
    );
  }

  /// An `if` element no longer hides duplicates that follow it.
  Future<void> test_listWithIfElementStillFindsDuplicate() async {
    await assertDiagnostics(
      r'''
List<int> build(bool flag) {
  return [1, if (flag) 2, 1];
}
''',
      [lint(55, 1)],
    );
  }

  // ---- Duplicate spreads and if elements ----

  Future<void> test_duplicateSpread() async {
    await assertDiagnostics(
      r'''
final base = [1, 2];
final values = [...base, ...base];
''',
      [lint(46, 7)],
    );
  }

  Future<void> test_duplicateSpreadInSet() async {
    await assertDiagnostics(
      r'''
final base = {1, 2};
final values = <int>{...base, ...base};
''',
      [lint(51, 7)],
    );
  }

  Future<void> test_duplicateSpreadInMap() async {
    await assertDiagnostics(
      r'''
final base = {'k': 'v'};
final values = {...base, ...base};
''',
      [lint(50, 7)],
    );
  }

  Future<void> test_duplicateIfElement() async {
    await assertDiagnostics(
      r'''
List<String> build(List<int> items) {
  return [
    if (items.isNotEmpty) 'value',
    if (items.isNotEmpty) 'value',
  ];
}
''',
      [lint(88, 29)],
    );
  }

  Future<void> test_differentSpreads() async {
    await assertNoDiagnostics(r'''
final a = [1];
final b = [2];
final values = [...a, ...b];
''');
  }

  Future<void> test_differentIfElements() async {
    await assertNoDiagnostics(r'''
List<String> build(List<int> items) {
  return [
    if (items.isNotEmpty) 'full',
    if (items.isEmpty) 'empty',
  ];
}
''');
  }

  Future<void> test_spreadOfMethodCallNotCompared() async {
    await assertNoDiagnostics(r'''
List<int> fetch() => [1];

final values = [...fetch(), ...fetch()];
''');
  }

  Future<void> test_differentValues() async {
    await assertNoDiagnostics(r'''
enum Status { active, inactive }

final values = [Status.active, Status.inactive];
''');
  }
}
