import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'many_lints_rule_test_base.dart';
import 'package:many_lints/src/rules/avoid_unsafe_collection_methods.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidUnsafeCollectionMethodsTest),
  );
}

@reflectiveTest
class AvoidUnsafeCollectionMethodsTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidUnsafeCollectionMethods();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_firstOnParameter() async {
    await assertDiagnostics(
      r'''
int firstItem(List<int> items) {
  return items.first;
}
''',
      [lint(42, 11)],
    );
  }

  Future<void> test_lastOnParameter() async {
    await assertDiagnostics(
      r'''
int lastItem(List<int> items) {
  return items.last;
}
''',
      [lint(41, 10)],
    );
  }

  Future<void> test_singleOnParameter() async {
    await assertDiagnostics(
      r'''
int onlyItem(Iterable<int> items) {
  return items.single;
}
''',
      // The test SDK's minimal Iterable declares no `single` getter, so the
      // resolution error is expected alongside the lint.
      [lint(45, 12), error(diag.undefinedGetter, 51, 6)],
    );
  }

  Future<void> test_reduceOnParameter() async {
    await assertDiagnostics(
      r'''
int total(Iterable<int> items) {
  return items.reduce((a, b) => a + b);
}
''',
      // The test SDK's minimal Iterable declares no `reduce` method.
      [lint(42, 29), error(diag.undefinedMethod, 48, 6)],
    );
  }

  Future<void> test_firstOnLocalVariable() async {
    await assertDiagnostics(
      r'''
int firstItem(Iterable<int> source) {
  final items = source.toList();
  return items.first;
}
''',
      [lint(80, 11)],
    );
  }

  Future<void> test_firstOnEmptyLiteral() async {
    await assertDiagnostics(
      r'''
int firstItem() {
  final items = <int>[];
  return items.first;
}
''',
      [lint(52, 11)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_guardedByIsNotEmpty() async {
    await assertNoDiagnostics(r'''
int? firstItem(List<int> items) {
  if (items.isNotEmpty) {
    return items.first;
  }
  return null;
}
''');
  }

  Future<void> test_guardedByIsEmptyEarlyReturn() async {
    await assertNoDiagnostics(r'''
int? firstItem(List<int> items) {
  if (items.isEmpty) return null;
  return items.first;
}
''');
  }

  Future<void> test_guardedByLengthCheck() async {
    await assertNoDiagnostics(r'''
int? firstItem(List<int> items) {
  if (items.length > 0) {
    return items.first;
  }
  return null;
}
''');
  }

  Future<void> test_firstOrNullIsSafe() async {
    await assertNoDiagnostics(r'''
int? firstItem(List<int> items) {
  return items.isEmpty ? null : items.first;
}
''');
  }

  Future<void> test_nonEmptyListLiteral() async {
    await assertNoDiagnostics(r'''
int firstItem() {
  return [1, 2, 3].first;
}
''');
  }

  Future<void> test_chainedExpressionNotReported() async {
    await assertNoDiagnostics(r'''
int firstEven(List<int> items) {
  return items.where((i) => i.isEven).first;
}
''');
  }

  Future<void> test_firstOnNonCollection() async {
    await assertNoDiagnostics(r'''
class Record {
  int get first => 1;
  int get last => 2;
}

int value(Record record) {
  return record.first;
}
''');
  }

  Future<void> test_reduceOnNonCollection() async {
    await assertNoDiagnostics(r'''
class Accumulator {
  int reduce(int Function(int, int) combine) => 0;
}

int value(Accumulator acc) {
  return acc.reduce((a, b) => a + b);
}
''');
  }

  Future<void> test_mapAccessIsNotReported() async {
    await assertNoDiagnostics(r'''
int? lookup(Map<String, int> values) {
  return values['key'];
}
''');
  }
}
