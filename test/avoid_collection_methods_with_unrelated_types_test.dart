import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_collection_methods_with_unrelated_types.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidCollectionMethodsWithUnrelatedTypesTest),
  );
}

@reflectiveTest
class AvoidCollectionMethodsWithUnrelatedTypesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidCollectionMethodsWithUnrelatedTypes();
    super.setUp();
  }

  // ── List.contains with unrelated type ──────────────────────────────

  Future<void> test_listContainsWithUnrelatedType() async {
    await assertDiagnostics(
      r'''
void f(List<int> list) {
  list.contains('a');
}
''',
      [lint(27, 18)],
    );
  }

  Future<void> test_listContainsWithRelatedType() async {
    await assertNoDiagnostics(r'''
void f(List<int> list) {
  list.contains(42);
}
''');
  }

  // ── Set.contains with unrelated type ───────────────────────────────

  Future<void> test_setContainsWithUnrelatedType() async {
    await assertDiagnostics(
      r'''
void f(Set<int> set) {
  set.contains('a');
}
''',
      [lint(25, 17)],
    );
  }

  Future<void> test_setContainsWithRelatedType() async {
    await assertNoDiagnostics(r'''
void f(Set<int> set) {
  set.contains(42);
}
''');
  }

  // ── Map.containsKey with unrelated type ────────────────────────────

  Future<void> test_mapContainsKeyWithUnrelatedType() async {
    await assertDiagnostics(
      r'''
void f(Map<int, String> map) {
  map.containsKey('a');
}
''',
      [lint(33, 20)],
    );
  }

  Future<void> test_mapContainsKeyWithRelatedType() async {
    await assertNoDiagnostics(r'''
void f(Map<int, String> map) {
  map.containsKey(42);
}
''');
  }

  // ── Map.containsValue with unrelated type ──────────────────────────

  Future<void> test_mapContainsValueWithUnrelatedType() async {
    await assertDiagnostics(
      r'''
void f(Map<int, String> map) {
  map.containsValue(42);
}
''',
      [lint(33, 21)],
    );
  }

  Future<void> test_mapContainsValueWithRelatedType() async {
    await assertNoDiagnostics(r'''
void f(Map<int, String> map) {
  map.containsValue('hello');
}
''');
  }

  // ── Map index access with unrelated key type ───────────────────────

  Future<void> test_mapIndexWithUnrelatedKeyType() async {
    await assertDiagnostics(
      r'''
void f(Map<int, String> map) {
  map['a'];
}
''',
      [lint(33, 8)],
    );
  }

  Future<void> test_mapIndexWithRelatedKeyType() async {
    await assertNoDiagnostics(r'''
void f(Map<int, String> map) {
  map[42];
}
''');
  }

  // ── List.remove with unrelated type ────────────────────────────────

  Future<void> test_listRemoveWithUnrelatedType() async {
    await assertDiagnostics(
      r'''
void f(List<int> list) {
  list.remove('a');
}
''',
      [lint(27, 16)],
    );
  }

  // ── Map.remove with unrelated key type ─────────────────────────────

  Future<void> test_mapRemoveWithUnrelatedKeyType() async {
    await assertDiagnostics(
      r'''
void f(Map<int, String> map) {
  map.remove('a');
}
''',
      [lint(33, 15)],
    );
  }

  // ── Set.lookup with unrelated type ─────────────────────────────────

  Future<void> test_setLookupWithUnrelatedType() async {
    await assertDiagnostics(
      r'''
void f(Set<int> set) {
  set.lookup('a');
}
''',
      [lint(25, 15)],
    );
  }

  // ── Subtype is related (no lint) ───────────────────────────────────

  Future<void> test_subtypeIsRelated() async {
    await assertNoDiagnostics(r'''
void f(List<num> list) {
  list.contains(42); // int is subtype of num
}
''');
  }

  Future<void> test_supertypeIsRelated() async {
    await assertNoDiagnostics(r'''
void f(List<int> list, num value) {
  list.contains(value); // num is supertype of int
}
''');
  }

  // ── Dynamic argument skipped ───────────────────────────────────────

  Future<void> test_dynamicArgument_noLint() async {
    await assertNoDiagnostics(r'''
void f(List<int> list, dynamic value) {
  list.contains(value);
}
''');
  }

  // ── Generic type parameter skipped ─────────────────────────────────

  Future<void> test_genericTypeParameter_noLint() async {
    await assertNoDiagnostics(r'''
void f<T>(List<int> list, T value) {
  list.contains(value);
}
''');
  }

  // ── Iterable.contains with unrelated type ──────────────────────────

  Future<void> test_iterableContainsWithUnrelatedType() async {
    await assertDiagnostics(
      r'''
void f(Iterable<int> iter) {
  iter.contains('a');
}
''',
      [lint(31, 18)],
    );
  }

  // ── Non-collection method — no lint ────────────────────────────────

  Future<void> test_nonCollectionMethod_noLint() async {
    await assertNoDiagnostics(r'''
void f(List<int> list) {
  list.add(42);
}
''');
  }
}
