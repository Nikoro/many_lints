import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/prefer_test_matchers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferTestMatchersTest));
}

@reflectiveTest
class PreferTestMatchersTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferTestMatchers();

    // Mock the matcher package with a Matcher base class
    newPackage('matcher').addFile('lib/matcher.dart', r'''
abstract class Matcher {
  const Matcher();
}

class _IsNull extends Matcher {
  const _IsNull();
}

class _IsNotNull extends Matcher {
  const _IsNotNull();
}

class _IsEmpty extends Matcher {
  const _IsEmpty();
}

class _IsTrue extends Matcher {
  const _IsTrue();
}

class _IsFalse extends Matcher {
  const _IsFalse();
}

class _Equals extends Matcher {
  final Object? expected;
  const _Equals(this.expected);
}

class _HasLength extends Matcher {
  final Object? expected;
  const _HasLength(this.expected);
}

class _IsA<T> extends Matcher {
  const _IsA();
}

const Matcher isNull = _IsNull();
const Matcher isNotNull = _IsNotNull();
const Matcher isEmpty = _IsEmpty();
const Matcher isTrue = _IsTrue();
const Matcher isFalse = _IsFalse();

Matcher equals(Object? expected) => _Equals(expected);
Matcher hasLength(Object? expected) => _HasLength(expected);
_IsA<T> isA<T>() => _IsA<T>();
''');

    // Mock test_api with expect/expectLater that use matcher package
    newPackage('test_api').addFile('lib/test_api.dart', r'''
import 'package:matcher/matcher.dart';
export 'package:matcher/matcher.dart';

void expect(dynamic actual, dynamic matcher) {}
void expectLater(dynamic actual, dynamic matcher) {}
''');

    super.setUp();
  }

  // ── Literal int as matcher ────────────────────────────────────────

  Future<void> test_literalInt_inExpect() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

void f() {
  expect([1, 2, 3].length, 1);
}
''',
      [lint(80, 1)],
    );
  }

  Future<void> test_literalInt_inExpectLater() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

void f() {
  expectLater([1, 2, 3].length, 1);
}
''',
      [lint(85, 1)],
    );
  }

  // ── Literal string as matcher ─────────────────────────────────────

  Future<void> test_literalString_inExpect() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

void f() {
  expect('hello', 'hello');
}
''',
      [lint(71, 7)],
    );
  }

  // ── Literal bool as matcher ───────────────────────────────────────

  Future<void> test_literalBool_inExpect() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(true, true);
}
''',
      [lint(68, 4)],
    );
  }

  // ── Variable (non-Matcher) as matcher ─────────────────────────────

  Future<void> test_intVariable_inExpect() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

void f() {
  final expected = 42;
  expect(1, expected);
}
''',
      [lint(88, 8)],
    );
  }

  // ── Matcher constants — no lint ───────────────────────────────────

  Future<void> test_isNull_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  int? value;
  expect(value, isNull);
}
''');
  }

  Future<void> test_isNotNull_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  int? value;
  expect(value, isNotNull);
}
''');
  }

  Future<void> test_isEmpty_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(<int>[], isEmpty);
}
''');
  }

  Future<void> test_isTrue_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(true, isTrue);
}
''');
  }

  Future<void> test_isFalse_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(false, isFalse);
}
''');
  }

  // ── Matcher function calls — no lint ──────────────────────────────

  Future<void> test_equals_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  expect(42, equals(42));
}
''');
  }

  Future<void> test_hasLength_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  expect([1, 2], hasLength(2));
}
''');
  }

  Future<void> test_isA_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  expect('hello', isA<String>());
}
''');
  }

  // ── expectLater with Matcher — no lint ────────────────────────────

  Future<void> test_expectLater_withMatcher_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  expectLater([1, 2, 3], hasLength(3));
}
''');
  }

  // ── Edge cases ────────────────────────────────────────────────────

  Future<void> test_nonExpectCall_noLint() async {
    await assertNoDiagnostics(r'''
void myExpect(dynamic actual, dynamic matcher) {}

void f() {
  myExpect(42, 42);
}
''');
  }

  Future<void> test_literalList_inExpect() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

void f() {
  expect([1, 2], [1, 2]);
}
''',
      [lint(70, 6)],
    );
  }

  Future<void> test_literalNull_inExpect() async {
    await assertDiagnostics(
      r'''
import 'package:test_api/test_api.dart';

void f() {
  int? value;
  expect(value, null);
}
''',
      [lint(83, 4)],
    );
  }
}
