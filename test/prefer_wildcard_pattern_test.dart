import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_wildcard_pattern.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferWildcardPatternTest));
}

@reflectiveTest
class PreferWildcardPatternTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferWildcardPattern();
    super.setUp();
  }

  // === Switch expression cases ===

  Future<void> test_switchExpression_objectPattern() async {
    await assertDiagnostics(
      r'''
String f(Object object) {
  return switch (object) {
    int() => 'int',
    Object() => 'other',
  };
}
''',
      [lint(77, 8)],
    );
  }

  // === Switch statement cases ===

  Future<void> test_switchStatement_objectPattern() async {
    await assertDiagnostics(
      r'''
void f(Object object) {
  switch (object) {
    case int():
      break;
    case Object():
      break;
  }
}
''',
      [lint(82, 8)],
    );
  }

  // === If-case cases ===

  Future<void> test_ifCase_objectPattern() async {
    await assertDiagnostics(
      r'''
void f(Object object) {
  if (object case Object()) {}
}
''',
      [lint(42, 8)],
    );
  }

  // === Nested patterns ===

  Future<void> test_logicalAndPattern_objectPattern() async {
    await assertDiagnostics(
      r'''
void f(Object object) {
  if (object case Object() && Object()) {}
}
''',
      [lint(42, 8), lint(54, 8)],
    );
  }

  // === No lint cases ===

  Future<void> test_noLint_wildcardPattern() async {
    await assertNoDiagnostics(r'''
String f(Object object) {
  return switch (object) {
    int() => 'int',
    _ => 'other',
  };
}
''');
  }

  Future<void> test_noLint_objectPatternWithFields() async {
    await assertNoDiagnostics(r'''
String f(Object object) {
  return switch (object) {
    Object(hashCode: final h) => 'hash: $h',
  };
}
''');
  }

  Future<void> test_noLint_specificTypePattern() async {
    await assertNoDiagnostics(r'''
String f(Object object) {
  return switch (object) {
    int() => 'int',
    String() => 'string',
    _ => 'other',
  };
}
''');
  }

  Future<void> test_noLint_noPatterns() async {
    await assertNoDiagnostics(r'''
String f(int value) {
  return switch (value) {
    1 => 'one',
    2 => 'two',
    _ => 'other',
  };
}
''');
  }
}
