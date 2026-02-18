import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_overriding_parent_equality.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(PreferOverridingParentEqualityTest),
  );
}

@reflectiveTest
class PreferOverridingParentEqualityTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferOverridingParentEquality();
    super.setUp();
  }

  // --- Positive cases (should trigger lint) ---

  Future<void> test_childMissingBothEqualsAndHashCode() async {
    await assertDiagnostics(
      r'''
class Parent {
  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other);
}

class Child extends Parent {
  final String value;
  Child(this.value);
}
''',
      [lint(134, 5)],
    );
  }

  Future<void> test_childMissingOnlyEquals() async {
    await assertDiagnostics(
      r'''
class Parent {
  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other);
}

class Child extends Parent {
  final String value;
  Child(this.value);

  @override
  int get hashCode => value.hashCode;
}
''',
      [lint(134, 5)],
    );
  }

  Future<void> test_childMissingOnlyHashCode() async {
    await assertDiagnostics(
      r'''
class Parent {
  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other);
}

class Child extends Parent {
  final String value;
  Child(this.value);

  @override
  bool operator ==(Object other) =>
      other is Child && value == other.value;
}
''',
      [lint(134, 5)],
    );
  }

  Future<void> test_grandparentOverridesEquality() async {
    await assertDiagnostics(
      r'''
class GrandParent {
  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other);
}

class Parent extends GrandParent {}

class Child extends Parent {
  final int x;
  Child(this.x);
}
''',
      [lint(139, 6), lint(176, 5)],
    );
  }

  Future<void> test_childWithNoFields() async {
    await assertDiagnostics(
      r'''
class Parent {
  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other);
}

class Child extends Parent {}
''',
      [lint(134, 5)],
    );
  }

  // --- Negative cases (should NOT trigger lint) ---

  Future<void> test_childOverridesBoth() async {
    await assertNoDiagnostics(r'''
class Parent {
  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other);
}

class Child extends Parent {
  final String value;
  Child(this.value);

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(Object other) =>
      other is Child && value == other.value;
}
''');
  }

  Future<void> test_parentDoesNotOverrideEquality() async {
    await assertNoDiagnostics(r'''
class Parent {
  final int x;
  Parent(this.x);
}

class Child extends Parent {
  final String y;
  Child(this.y) : super(0);
}
''');
  }

  Future<void> test_parentOnlyOverridesEquals() async {
    await assertNoDiagnostics(r'''
class Parent {
  @override
  bool operator ==(Object other) => identical(this, other);
}

class Child extends Parent {
  final String value;
  Child(this.value);
}
''');
  }

  Future<void> test_parentOnlyOverridesHashCode() async {
    await assertNoDiagnostics(r'''
class Parent {
  @override
  int get hashCode => 42;
}

class Child extends Parent {
  final String value;
  Child(this.value);
}
''');
  }

  Future<void> test_abstractChildIsSkipped() async {
    await assertNoDiagnostics(r'''
class Parent {
  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other);
}

abstract class Child extends Parent {
  final String value;
  Child(this.value);
}
''');
  }

  Future<void> test_noSuperclass() async {
    await assertNoDiagnostics(r'''
class Standalone {
  final int x;
  Standalone(this.x);
}
''');
  }
}
