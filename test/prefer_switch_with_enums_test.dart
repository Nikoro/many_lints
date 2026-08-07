import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_switch_with_enums.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferSwitchWithEnumsTest));
}

@reflectiveTest
class PreferSwitchWithEnumsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferSwitchWithEnums();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_threeBranchChain() async {
    await assertDiagnostics(
      r'''
enum Status { active, inactive, pending }

String describe(Status status) {
  if (status == Status.active) {
    return 'Active';
  } else if (status == Status.inactive) {
    return 'Inactive';
  } else if (status == Status.pending) {
    return 'Pending';
  }
  return '';
}
''',
      [lint(82, 23)],
    );
  }

  Future<void> test_reversedOperands() async {
    await assertDiagnostics(
      r'''
enum Status { active, inactive, pending }

String describe(Status status) {
  if (Status.active == status) {
    return 'Active';
  } else if (Status.inactive == status) {
    return 'Inactive';
  } else if (Status.pending == status) {
    return 'Pending';
  }
  return '';
}
''',
      [lint(82, 23)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_twoBranchChainBelowThreshold() async {
    await assertNoDiagnostics(r'''
enum Status { active, inactive }

String describe(Status status) {
  if (status == Status.active) {
    return 'Active';
  } else if (status == Status.inactive) {
    return 'Inactive';
  }
  return '';
}
''');
  }

  Future<void> test_switchAlreadyUsed() async {
    await assertNoDiagnostics(r'''
enum Status { active, inactive, pending }

String describe(Status status) => switch (status) {
  Status.active => 'Active',
  Status.inactive => 'Inactive',
  Status.pending => 'Pending',
};
''');
  }

  Future<void> test_differentSubjects() async {
    await assertNoDiagnostics(r'''
enum Status { active, inactive, pending }

String describe(Status a, Status b) {
  if (a == Status.active) {
    return 'A active';
  } else if (b == Status.inactive) {
    return 'B inactive';
  } else if (a == Status.pending) {
    return 'A pending';
  }
  return '';
}
''');
  }

  Future<void> test_nonEnumComparisons() async {
    await assertNoDiagnostics(r'''
String describe(int value) {
  if (value == 1) {
    return 'one';
  } else if (value == 2) {
    return 'two';
  } else if (value == 3) {
    return 'three';
  }
  return '';
}
''');
  }

  Future<void> test_mixedConditions() async {
    await assertNoDiagnostics(r'''
enum Status { active, inactive, pending }

String describe(Status status, bool flag) {
  if (status == Status.active) {
    return 'Active';
  } else if (flag) {
    return 'Flagged';
  } else if (status == Status.pending) {
    return 'Pending';
  }
  return '';
}
''');
  }

  Future<void> test_nullableEnum() async {
    await assertNoDiagnostics(r'''
enum Status { active, inactive, pending }

String describe(Status? status) {
  if (status == Status.active) {
    return 'Active';
  } else if (status == Status.inactive) {
    return 'Inactive';
  } else if (status == Status.pending) {
    return 'Pending';
  }
  return '';
}
''');
  }
}
