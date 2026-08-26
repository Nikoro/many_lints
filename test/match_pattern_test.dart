import 'package:many_lints/src/rules/match_pattern.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(MatchPatternTest));
}

@reflectiveTest
class MatchPatternTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = MatchPattern();
    super.setUp();
  }

  /// Writes the config that gives this policy rule something to match.
  void _configure(String patterns) {
    newFile('$testPackageRootPath/many_lints.yaml', '''
rules:
  match_pattern:
    patterns:
$patterns
''');
  }

  // ---- Silent until configured ----

  Future<void> test_silentWithoutConfiguration() async {
    await assertNoDiagnostics(r'''
Future<void> g() async {}

void run() {
  unawaited(g());
}

void unawaited(Object? f) {}
''');
  }

  // ---- Positive cases ----

  Future<void> test_methodInvocationMatches() async {
    _configure(r"""      - find: '^unawaited\((.+)\)$'
        replace: '\$1.unawaited()'
        message: 'Prefer the trailing form.'""");

    await assertDiagnostics(
      r'''
void unawaited(Object? f) {}

void run() {
  unawaited(1);
}
''',
      [lint(45, 12)],
    );
  }

  Future<void> test_propertyAccessMatches() async {
    _configure(r"""      - node: propertyAccess
        find: '^theme\(\)\.text$'
        message: 'Use the context extension.'""");

    await assertDiagnostics(
      r'''
class T {
  String get text => '';
}

T theme() => T();

void run() {
  theme().text;
}
''',
      [lint(72, 12)],
    );
  }

  Future<void> test_messageIsAppended() async {
    _configure(r"""      - find: '^banned\(\)$'
        message: 'Use the seam.'""");

    await assertDiagnostics(
      r'''
void banned() {}

void run() {
  banned();
}
''',
      [lint(33, 8)],
    );
  }

  // ---- Negative cases ----

  Future<void> test_nodeKindIsRespected() async {
    // A propertyAccess pattern must not match a call of the same text shape.
    _configure(r"""      - node: propertyAccess
        find: '^unawaited\(1\)$'""");

    await assertNoDiagnostics(r'''
void unawaited(Object? f) {}

void run() {
  unawaited(1);
}
''');
  }

  Future<void> test_patternIsAnchoredToTheWholeNode() async {
    // `awaited` is a substring of `unawaited`; an unanchored match would hit.
    _configure(r"""      - find: 'awaited\(1\)'""");

    await assertNoDiagnostics(r'''
void unawaited(Object? f) {}

void run() {
  unawaited(1);
}
''');
  }

  Future<void> test_inGlobLimitsWhereItApplies() async {
    _configure(r"""      - find: '^banned\(\)$'
        in: ['lib/other/**']""");

    await assertNoDiagnostics(r'''
void banned() {}

void run() {
  banned();
}
''');
  }

  Future<void> test_invalidRegexDropsTheEntry() async {
    // A malformed option degrades quietly: a plugin cannot report against YAML.
    _configure(r"""      - find: '^unclosed\('""");

    await assertNoDiagnostics(r'''
void run() {}
''');
  }

  Future<void> test_unknownNodeKindDropsTheEntry() async {
    // A typo must not silently retarget the pattern at calls.
    _configure(r"""      - node: statement
        find: '^banned\(\)$'""");

    await assertNoDiagnostics(r'''
void banned() {}

void run() {
  banned();
}
''');
  }
}
