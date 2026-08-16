import 'package:many_lints/src/rules/match_getter_setter_field_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(MatchGetterSetterFieldNamesTest),
  );
}

@reflectiveTest
class MatchGetterSetterFieldNamesTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = MatchGetterSetterFieldNames();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_setterWritesTheWrongField() async {
    await assertDiagnostics(
      r'''
class C {
  int _width = 0;
  int _height = 0;

  int get width => _width;
  set width(int value) => _height = value;
}
''',
      [lint(81, 5)],
    );
  }

  Future<void> test_blockBodiesAlsoCompared() async {
    await assertDiagnostics(
      r'''
class C {
  int _a = 0;
  int _b = 0;

  int get value {
    return _a;
  }

  set value(int v) {
    _b = v;
  }
}
''',
      [lint(83, 5)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_matchingPair() async {
    await assertNoDiagnostics(r'''
class C {
  int _width = 0;

  int get width => _width;
  set width(int value) => _width = value;
}
''');
  }

  Future<void> test_thisQualifiedPairMatches() async {
    await assertNoDiagnostics(r'''
class C {
  int width = 0;

  int get doubled => width;
  set doubled(int value) => this.width = value;
}
''');
  }

  Future<void> test_getterWithoutSetter() async {
    await assertNoDiagnostics(r'''
class C {
  int _a = 0;
  int get a => _a;
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_computedGetterIsSkipped() async {
    // No single field to compare against, so the rule must not guess.
    await assertNoDiagnostics(r'''
class C {
  int _a = 0;
  int _b = 0;

  int get total => _a + _b;
  set total(int value) => _a = value;
}
''');
  }

  Future<void> test_validatingSetterIsSkipped() async {
    await assertNoDiagnostics(r'''
class C {
  int _a = 0;
  int _b = 0;

  int get a => _a;
  set a(int value) {
    if (value < 0) return;
    _b = value;
  }
}
''');
  }

  Future<void> test_compoundAssignmentIsSkipped() async {
    // `+=` reads the field too, so an asymmetry can be deliberate.
    await assertNoDiagnostics(r'''
class C {
  int _a = 0;
  int _b = 0;

  int get a => _a;
  set a(int value) => _b += value;
}
''');
  }
}
