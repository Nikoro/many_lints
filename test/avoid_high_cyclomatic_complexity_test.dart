import 'package:many_lints/src/rules/avoid_high_cyclomatic_complexity.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidHighCyclomaticComplexityTest),
  );
}

@reflectiveTest
class AvoidHighCyclomaticComplexityTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidHighCyclomaticComplexity();
    super.setUp();
  }

  // ---- Positive cases (should trigger lint) ----

  Future<void> test_manyIfStatements() async {
    // 10 ifs + 1 = 11, over the default of 10.
    final body = List.generate(
      10,
      (i) => '  if (n == $i) print($i);',
    ).join('\n');

    await assertDiagnostics(
      '''
void f(int n) {
$body
}
''',
      [lint(5, 1)],
    );
  }

  Future<void> test_logicalOperatorsCount() async {
    // Ten `&&` operators plus the entry path is a complexity of 11.
    await assertDiagnostics(
      r'''
bool f(bool a, bool b, bool c, bool d, bool e, bool g, bool h, bool i, bool j,
    bool k, bool l) {
  return a && b && c && d && e && g && h && i && j && k && l;
}
''',
      [lint(5, 1)],
    );
  }

  // ---- Negative cases (should NOT trigger lint) ----

  Future<void> test_straightLineCode() async {
    final body = List.generate(30, (i) => '  var x$i = $i;').join('\n');

    await assertNoDiagnostics('''
void f() {
$body
}
''');
  }

  Future<void> test_aFewBranches() async {
    await assertNoDiagnostics(r'''
int f(int n) {
  if (n < 0) return -1;
  if (n == 0) return 0;
  return 1;
}
''');
  }

  // ---- Edge cases ----

  Future<void> test_exhaustiveEnumSwitchCountsAsOne() async {
    // Twelve cases the compiler proves exhaustive are one decision, not twelve
    // — otherwise the rule reports the exhaustive matching Dart 3 encourages.
    await assertNoDiagnostics(r'''
enum Suit { a, b, c, d, e, f, g, h, i, j, k, l }

String f(Suit suit) {
  return switch (suit) {
    Suit.a => 'a',
    Suit.b => 'b',
    Suit.c => 'c',
    Suit.d => 'd',
    Suit.e => 'e',
    Suit.f => 'f',
    Suit.g => 'g',
    Suit.h => 'h',
    Suit.i => 'i',
    Suit.j => 'j',
    Suit.k => 'k',
    Suit.l => 'l',
  };
}
''');
  }

  Future<void> test_nonExhaustiveSwitchCountsEveryCase() async {
    await assertDiagnostics(
      r'''
String f(int n) {
  switch (n) {
    case 1: return '1';
    case 2: return '2';
    case 3: return '3';
    case 4: return '4';
    case 5: return '5';
    case 6: return '6';
    case 7: return '7';
    case 8: return '8';
    case 9: return '9';
    case 10: return '10';
    default: return '?';
  }
}
''',
      [lint(7, 1)],
    );
  }

  // `==` and `copyWith` grow one branch per field, not per decision, and were
  // the majority of the rule's hits on a production codebase.
  Future<void> test_equalsOperatorIsFieldCountShaped() async {
    await assertNoDiagnostics(r'''
class C {
  final int a, b, c, d, e, f, g, h, i, j, k, l;

  const C(this.a, this.b, this.c, this.d, this.e, this.f, this.g, this.h,
      this.i, this.j, this.k, this.l);

  @override
  bool operator ==(Object other) =>
      other is C &&
      other.a == a &&
      other.b == b &&
      other.c == c &&
      other.d == d &&
      other.e == e &&
      other.f == f &&
      other.g == g &&
      other.h == h &&
      other.i == i &&
      other.j == j &&
      other.k == k &&
      other.l == l;

  @override
  int get hashCode => 0;
}
''');
  }

  Future<void> test_copyWithIsFieldCountShaped() async {
    await assertNoDiagnostics(r'''
class C {
  final int a, b, c, d, e, f, g, h, i, j, k, l;

  const C(this.a, this.b, this.c, this.d, this.e, this.f, this.g, this.h,
      this.i, this.j, this.k, this.l);

  C copyWith({
    int? a, int? b, int? c, int? d, int? e, int? f,
    int? g, int? h, int? i, int? j, int? k, int? l,
  }) =>
      C(a ?? this.a, b ?? this.b, c ?? this.c, d ?? this.d, e ?? this.e,
          f ?? this.f, g ?? this.g, h ?? this.h, i ?? this.i, j ?? this.j,
          k ?? this.k, l ?? this.l);
}
''');
  }

  // A validating constructor's checks are real, independent decisions, so it
  // must still report — this was a true positive on the same codebase.
  Future<void> test_validatingConstructorStillReports() async {
    await assertDiagnostics(
      r'''
class C {
  C(int a, int b, int c, int d, int e, int f, int g, int h, int i, int j) {
    if (a < 0) throw ArgumentError('a');
    if (b < 0) throw ArgumentError('b');
    if (c < 0) throw ArgumentError('c');
    if (d < 0) throw ArgumentError('d');
    if (e < 0) throw ArgumentError('e');
    if (f < 0) throw ArgumentError('f');
    if (g < 0) throw ArgumentError('g');
    if (h < 0) throw ArgumentError('h');
    if (i < 0) throw ArgumentError('i');
    if (j < 0) throw ArgumentError('j');
  }
}
''',
      [lint(12, 487)],
    );
  }

  Future<void> test_nestedCallbackIsMeasuredSeparately() async {
    final conditions = List.generate(
      10,
      (i) => '    if (e == $i) print($i);',
    ).join('\n');

    await assertNoDiagnostics('''
void f(List<int> xs) {
  xs.forEach((e) {
$conditions
  });
}
''');
  }
}
