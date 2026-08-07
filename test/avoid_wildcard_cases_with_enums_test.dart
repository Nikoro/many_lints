import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_wildcard_cases_with_enums.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidWildcardCasesWithEnumsTest),
  );
}

@reflectiveTest
class AvoidWildcardCasesWithEnumsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidWildcardCasesWithEnums();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_wildcardInSwitchExpression() async {
    await assertDiagnostics(
      r'''
enum Status { active, inactive, pending }

String describe(Status status) => switch (status) {
  Status.active => 'Active',
  _ => 'Other',
};
''',
      [lint(126, 1)],
    );
  }

  Future<void> test_wildcardInSwitchStatement() async {
    await assertDiagnostics(
      r'''
enum Status { active, inactive, pending }

void describe(Status status) {
  switch (status) {
    case Status.active:
      print('Active');
    case _:
      print('Other');
  }
}
''',
      [lint(150, 1)],
    );
  }

  Future<void> test_defaultInSwitchStatement() async {
    await assertDiagnostics(
      r'''
enum Status { active, inactive, pending }

void describe(Status status) {
  switch (status) {
    case Status.active:
      print('Active');
    default:
      print('Other');
  }
}
''',
      [lint(145, 7)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_exhaustiveSwitchExpression() async {
    await assertNoDiagnostics(r'''
enum Status { active, inactive, pending }

String describe(Status status) => switch (status) {
  Status.active => 'Active',
  Status.inactive => 'Inactive',
  Status.pending => 'Pending',
};
''');
  }

  Future<void> test_exhaustiveSwitchStatement() async {
    await assertNoDiagnostics(r'''
enum Status { active, inactive }

void describe(Status status) {
  switch (status) {
    case Status.active:
      print('Active');
    case Status.inactive:
      print('Inactive');
  }
}
''');
  }

  Future<void> test_wildcardOnNullableEnum() async {
    await assertNoDiagnostics(r'''
enum Status { active, inactive }

String describe(Status? status) => switch (status) {
  Status.active => 'Active',
  Status.inactive => 'Inactive',
  _ => 'None',
};
''');
  }

  Future<void> test_guardedWildcard() async {
    await assertNoDiagnostics(r'''
enum Status { active, inactive, pending }

String describe(Status status, bool flag) => switch (status) {
  Status.active => 'Active',
  _ when flag => 'Flagged',
  Status.inactive => 'Inactive',
  Status.pending => 'Pending',
};
''');
  }

  Future<void> test_wildcardOnNonEnum() async {
    await assertNoDiagnostics(r'''
String describe(int value) => switch (value) {
  0 => 'zero',
  _ => 'other',
};
''');
  }

  Future<void> test_wildcardOnSealedClass() async {
    await assertNoDiagnostics(r'''
sealed class Shape {}
class Circle extends Shape {}
class Square extends Shape {}

String describe(Shape shape) => switch (shape) {
  Circle() => 'circle',
  _ => 'other',
};
''');
  }
}
