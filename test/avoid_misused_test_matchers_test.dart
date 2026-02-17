import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/avoid_misused_test_matchers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidMisusedTestMatchersTest),
  );
}

@reflectiveTest
class AvoidMisusedTestMatchersTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidMisusedTestMatchers();

    // Mock the test_api package (can't use 'test' — conflicts with dev dep)
    newPackage('test_api').addFile('lib/test_api.dart', r'''
void expect(dynamic actual, dynamic matcher) {}

const isNull = 1;
const isNotNull = 2;
const isEmpty = 3;
const isNotEmpty = 4;
const isList = 5;
const isMap = 6;
const isZero = 7;
const isNaN = 8;
const isPositive = 9;
const isNegative = 10;
const isTrue = 11;
const isFalse = 12;

int hasLength(dynamic expected) => 0;
''');

    super.setUp();
  }

  // ── isNull on non-nullable type ─────────────────────────────────────

  Future<void> test_isNull_onNonNullableInt() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(42, isNull);
}
''',
      [lint(66, 6)],
    );
  }

  Future<void> test_isNull_onNullableInt() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  int? value;
  expect(value, isNull);
}
''');
  }

  // ── isNotNull on non-nullable type ──────────────────────────────────

  Future<void> test_isNotNull_onNonNullableInt() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(42, isNotNull);
}
''',
      [lint(66, 9)],
    );
  }

  Future<void> test_isNotNull_onNullableString() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  String? value;
  expect(value, isNotNull);
}
''');
  }

  // ── isEmpty on type without isEmpty ─────────────────────────────────

  Future<void> test_isEmpty_onInt() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(42, isEmpty);
}
''',
      [lint(66, 7)],
    );
  }

  Future<void> test_isEmpty_onList() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(<int>[], isEmpty);
}
''');
  }

  Future<void> test_isEmpty_onString() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  expect('', isEmpty);
}
''');
  }

  Future<void> test_isEmpty_onMap() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(<String, int>{}, isEmpty);
}
''');
  }

  // ── isNotEmpty on type without isNotEmpty ────────────────────────────

  Future<void> test_isNotEmpty_onInt() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(42, isNotEmpty);
}
''',
      [lint(66, 10)],
    );
  }

  Future<void> test_isNotEmpty_onSet() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(<int>{1, 2}, isNotEmpty);
}
''');
  }

  // ── isList on non-List type ─────────────────────────────────────────

  Future<void> test_isList_onSet() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(<int>{1}, isList);
}
''',
      [lint(72, 6)],
    );
  }

  Future<void> test_isList_onString() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

void f() {
  expect('hello', isList);
}
''',
      [lint(71, 6)],
    );
  }

  Future<void> test_isList_onList() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(<int>[1, 2], isList);
}
''');
  }

  // ── isMap on non-Map type ───────────────────────────────────────────

  Future<void> test_isMap_onList() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(<int>[1], isMap);
}
''',
      [lint(72, 5)],
    );
  }

  Future<void> test_isMap_onMap() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(<String, int>{}, isMap);
}
''');
  }

  // ── hasLength on type without length ────────────────────────────────

  Future<void> test_hasLength_onInt() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(42, hasLength(1));
}
''',
      [lint(66, 12)],
    );
  }

  Future<void> test_hasLength_onList() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(<int>[1, 2], hasLength(2));
}
''');
  }

  Future<void> test_hasLength_onString() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  expect('hello', hasLength(5));
}
''');
  }

  // ── isZero on non-num type ──────────────────────────────────────────

  Future<void> test_isZero_onString() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

void f() {
  expect('hello', isZero);
}
''',
      [lint(71, 6)],
    );
  }

  Future<void> test_isZero_onInt() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(0, isZero);
}
''');
  }

  Future<void> test_isZero_onDouble() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(0.0, isZero);
}
''');
  }

  // ── isNaN on non-num type ───────────────────────────────────────────

  Future<void> test_isNaN_onString() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

void f() {
  expect('hello', isNaN);
}
''',
      [lint(71, 5)],
    );
  }

  Future<void> test_isNaN_onDouble() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(double.nan, isNaN);
}
''');
  }

  // ── isPositive on non-num type ──────────────────────────────────────

  Future<void> test_isPositive_onString() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

void f() {
  expect('hello', isPositive);
}
''',
      [lint(71, 10)],
    );
  }

  Future<void> test_isPositive_onNum() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(5, isPositive);
}
''');
  }

  // ── isNegative on non-num type ──────────────────────────────────────

  Future<void> test_isNegative_onBool() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(true, isNegative);
}
''',
      [lint(68, 10)],
    );
  }

  Future<void> test_isNegative_onInt() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(-5, isNegative);
}
''');
  }

  // ── isTrue on non-bool type ─────────────────────────────────────────

  Future<void> test_isTrue_onInt() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(42, isTrue);
}
''',
      [lint(66, 6)],
    );
  }

  Future<void> test_isTrue_onBool() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(true, isTrue);
}
''');
  }

  // ── isFalse on non-bool type ────────────────────────────────────────

  Future<void> test_isFalse_onString() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

void f() {
  expect('hello', isFalse);
}
''',
      [lint(71, 7)],
    );
  }

  Future<void> test_isFalse_onBool() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(false, isFalse);
}
''');
  }

  // ── Edge cases ──────────────────────────────────────────────────────

  Future<void> test_dynamic_actual_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f(dynamic value) {
  expect(value, isNull);
}
''');
  }

  Future<void> test_nonExpectCall_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void expect2(dynamic actual, dynamic matcher) {}

void f() {
  expect2(42, isNull);
}
''');
  }

  Future<void> test_unknownMatcher_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(42, 'some string');
}
''');
  }

  Future<void> test_isNull_onNonNullableString() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

void f() {
  const s = 'hello';
  expect(s, isNull);
}
''',
      [lint(86, 6)],
    );
  }

  Future<void> test_isList_onInt() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(42, isList);
}
''',
      [lint(66, 6)],
    );
  }

  Future<void> test_isMap_onString() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

void f() {
  expect('hello', isMap);
}
''',
      [lint(71, 5)],
    );
  }

  Future<void> test_hasLength_onMap() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(<String, int>{}, hasLength(0));
}
''');
  }
}
