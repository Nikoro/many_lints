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

  void _configure(String patterns) {
    newFile('$testPackageRootPath/many_lints.yaml', '''
rules:
  match_pattern:
    patterns:
$patterns
''');
  }

  Future<void> test_silentWithoutConfiguration() async {
    await assertNoDiagnostics(r'''
Future<void> g() async {}

void run() {
  unawaited(g());
}

void unawaited(Object? f) {}
''');
  }

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

  Future<void> test_propertyAccessPatternDoesNotMatchACall() async {
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
    _configure(r"""      - find: '^unclosed\('""");

    await assertNoDiagnostics(r'''
void run() {}
''');
  }

  Future<void>
  test_unknownNodeKindDropsTheEntryRatherThanMatchingCalls() async {
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
