import 'package:many_lints/src/rule_config.dart';
import 'package:many_lints/src/rules/map_keys_ordering.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(MapKeysOrderingTest));
}

@reflectiveTest
class MapKeysOrderingTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = MapKeysOrdering();
    super.setUp();

    ConfigLoader.clearCache();
    newFile(
      '$testPackageRootPath/${ConfigLoader.fileName}',
      'rules:\n  map_keys_ordering:\n    order: alphabetical\n',
    );
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_unorderedStringKeys() async {
    await assertDiagnostics(
      r'''
const m = {
  'banana': 1,
  'apple': 2,
  'cherry': 3,
  'date': 4,
  'elder': 5,
};
''',
      [lint(29, 7)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_orderedKeys() async {
    await assertNoDiagnostics(r'''
const m = {
  'apple': 1,
  'banana': 2,
  'cherry': 3,
  'date': 4,
  'elder': 5,
};
''');
  }

  Future<void> test_shortMapIsBelowTheThreshold() async {
    await assertNoDiagnostics(r'''
const m = {'banana': 1, 'apple': 2};
''');
  }

  // ---- Edge cases ----

  Future<void> test_computedKeyMakesTheLiteralUnsortable() async {
    // Ordering the rest around a computed key would produce an arrangement
    // the user cannot reach.
    await assertNoDiagnostics(r'''
String k() => 'x';

final m = {
  'banana': 1,
  k(): 2,
  'apple': 3,
  'cherry': 4,
  'date': 5,
};
''');
  }

  Future<void> test_spreadMakesTheLiteralUnsortable() async {
    await assertNoDiagnostics(r'''
const other = {'zzz': 0};

const m = {
  'banana': 1,
  ...other,
  'apple': 2,
  'cherry': 3,
  'date': 4,
};
''');
  }

  Future<void> test_setLiteralIsNotAMap() async {
    await assertNoDiagnostics(r'''
const s = {'banana', 'apple', 'cherry', 'date', 'elder'};
''');
  }
}
