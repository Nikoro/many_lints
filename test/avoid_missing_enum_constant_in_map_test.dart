import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_missing_enum_constant_in_map.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidMissingEnumConstantInMapTest),
  );
}

@reflectiveTest
class AvoidMissingEnumConstantInMapTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidMissingEnumConstantInMap();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_missingOneConstant() async {
    await assertDiagnostics(
      r'''
enum Status { active, inactive, pending }

const labels = <Status, String>{
  Status.active: 'Active',
  Status.inactive: 'Inactive',
};
''',
      [lint(58, 77)],
    );
  }

  Future<void> test_missingTwoConstants() async {
    await assertDiagnostics(
      r'''
enum Status { active, inactive, pending }

const labels = <Status, String>{
  Status.active: 'Active',
};
''',
      [lint(58, 46)],
    );
  }

  Future<void> test_inferredKeyType() async {
    await assertDiagnostics(
      r'''
enum Status { active, inactive }

final labels = {
  Status.active: 'Active',
};
''',
      [lint(49, 30)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_allConstantsPresent() async {
    await assertNoDiagnostics(r'''
enum Status { active, inactive, pending }

const labels = <Status, String>{
  Status.active: 'Active',
  Status.inactive: 'Inactive',
  Status.pending: 'Pending',
};
''');
  }

  Future<void> test_emptyMap() async {
    await assertNoDiagnostics(r'''
enum Status { active, inactive }

final labels = <Status, String>{};
''');
  }

  Future<void> test_nonEnumKeys() async {
    await assertNoDiagnostics(r'''
const labels = <String, String>{
  'active': 'Active',
};
''');
  }

  Future<void> test_mapWithSpread() async {
    await assertNoDiagnostics(r'''
enum Status { active, inactive, pending }

const base = <Status, String>{
  Status.active: 'Active',
  Status.inactive: 'Inactive',
  Status.pending: 'Pending',
};

final labels = <Status, String>{
  ...base,
  Status.active: 'Overridden',
};
''');
  }

  Future<void> test_mapWithIfElement() async {
    await assertNoDiagnostics(r'''
enum Status { active, inactive }

Map<Status, String> build(bool flag) {
  return <Status, String>{
    Status.active: 'Active',
    if (flag) Status.inactive: 'Inactive',
  };
}
''');
  }

  Future<void> test_setLiteralIsNotAMap() async {
    await assertNoDiagnostics(r'''
enum Status { active, inactive }

final statuses = <Status>{Status.active};
''');
  }

  Future<void> test_computedKeyIsNotEnumerable() async {
    await assertNoDiagnostics(r'''
enum Status { active, inactive }

Map<Status, String> build(Status current) {
  return <Status, String>{
    current: 'Current',
  };
}
''');
  }
}
