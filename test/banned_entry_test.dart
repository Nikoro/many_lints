import 'package:many_lints/src/banned_entry.dart';
import 'package:many_lints/src/rule_config.dart';
import 'package:test/test.dart';

/// Parses [yaml] as a `many_lints.yaml` document and reads rule `r`'s entries.
List<BannedEntry> entriesOf(String yaml) =>
    readBannedEntries(ManyLintsConfig.parse(yaml).forRule('r'));

void main() {
  group('readBannedEntries', () {
    test('returns nothing when the rule is unconfigured', () {
      expect(entriesOf('rules:\n  other:\n    banned: [x]\n'), isEmpty);
    });

    test('reads a deny list', () {
      final entries = entriesOf('''
rules:
  r:
    banned:
      - deny: [a, b]
''');

      expect(entries, hasLength(1));
      expect(entries.single.deny, {'a', 'b'});
    });

    test('accepts a bare scalar as a one-item list', () {
      // A single value is the common case; requiring a list for it is a
      // needless "why is my config ignored" trap.
      final entries = entriesOf('''
rules:
  r:
    banned:
      - deny: a
''');

      expect(entries.single.deny, {'a'});
    });

    test('drops an entry that denies nothing', () {
      // An entry with only a message would match nothing, so it never
      // reaches a rule.
      expect(
        entriesOf('''
rules:
  r:
    banned:
      - message: why
'''),
        isEmpty,
      );
    });

    test('a malformed banned value degrades to no entries', () {
      expect(entriesOf('rules:\n  r:\n    banned: "not a list"\n'), isEmpty);
    });

    test('keeps well-formed entries alongside malformed ones', () {
      // A bad entry must cost the user that entry and nothing else.
      final entries = entriesOf('''
rules:
  r:
    banned:
      - deny: [ok]
      - 42
      - deny: [also_ok]
''');

      expect(entries, hasLength(2));
    });

    test('reads paths and message', () {
      final entries = entriesOf('''
rules:
  r:
    banned:
      - deny: [a]
        in: ['lib/domain/**']
        message: 'Not here.'
''');

      expect(entries.single.paths, ['lib/domain/**']);
      expect(entries.single.message, 'Not here.');
    });

    test('an empty message is treated as absent', () {
      final entries = entriesOf('''
rules:
  r:
    banned:
      - deny: [a]
        message: ''
''');

      expect(entries.single.message, isNull);
      expect(messageSuffix(entries.single), isEmpty);
    });

    test('an invalid regex is dropped without throwing', () {
      final entries = entriesOf('''
rules:
  r:
    banned:
      - deny: [a]
        deny_pattern: ['[unclosed']
''');

      expect(entries.single.denyPatterns, isEmpty);
      expect(entries.single.deny, {'a'});
    });
  });

  group('BannedEntry.matches', () {
    BannedEntry entryOf(String yaml) => entriesOf(yaml).single;

    test('deny matches exactly, not as a substring', () {
      // The headline choice here: regex matching would match substrings, so
      // that banning `visibleForTesting` also hits `notVisibleForTesting`.
      final entry = entryOf('''
rules:
  r:
    banned:
      - deny: [visibleForTesting]
''');

      expect(entry.matches('visibleForTesting'), isTrue);
      expect(entry.matches('notVisibleForTesting'), isFalse);
      expect(entry.matches('visibleForTestingOnly'), isFalse);
    });

    test('deny_pattern is anchored to the whole value', () {
      final entry = entryOf('''
rules:
  r:
    banned:
      - deny_pattern: ['legacy_.*']
''');

      expect(entry.matches('legacy_user'), isTrue);
      expect(entry.matches('not_legacy_user'), isFalse);
    });

    test('an alternation pattern still anchors as a whole', () {
      // Anchoring by wrapping the source in `^(?:...)$` would be fine here,
      // but a naive `^...$` concatenation would rebind the alternation.
      final entry = entryOf('''
rules:
  r:
    banned:
      - deny_pattern: ['foo|bar']
''');

      expect(entry.matches('foo'), isTrue);
      expect(entry.matches('bar'), isTrue);
      expect(entry.matches('foobar'), isFalse);
      expect(entry.matches('xfoo'), isFalse);
    });

    test('deny and deny_pattern combine', () {
      final entry = entryOf('''
rules:
  r:
    banned:
      - deny: [exact]
        deny_pattern: ['p.*']
''');

      expect(entry.matches('exact'), isTrue);
      expect(entry.matches('pattern'), isTrue);
      expect(entry.matches('neither'), isFalse);
    });
  });

  group('BannedEntry.appliesTo', () {
    BannedEntry entryOf(String yaml) => entriesOf(yaml).single;

    test('an entry with no paths applies everywhere', () {
      final entry = entryOf('''
rules:
  r:
    banned:
      - deny: [a]
''');

      expect(entry.appliesTo('lib/anything.dart'), isTrue);
      expect(entry.appliesTo(null), isTrue);
    });

    test('a scoped entry applies only inside its globs', () {
      final entry = entryOf('''
rules:
  r:
    banned:
      - deny: [a]
        in: ['lib/domain/**']
''');

      expect(entry.appliesTo('lib/domain/user.dart'), isTrue);
      expect(entry.appliesTo('lib/domain/nested/user.dart'), isTrue);
      expect(entry.appliesTo('lib/ui/page.dart'), isFalse);
    });

    test('a scoped entry does not apply to a file outside the package', () {
      final entry = entryOf('''
rules:
  r:
    banned:
      - deny: [a]
        in: ['lib/**']
''');

      expect(entry.appliesTo(null), isFalse);
    });

    test('several globs are ORed', () {
      final entry = entryOf('''
rules:
  r:
    banned:
      - deny: [a]
        in: ['lib/domain/**', 'lib/data/**']
''');

      expect(entry.appliesTo('lib/domain/user.dart'), isTrue);
      expect(entry.appliesTo('lib/data/user.dart'), isTrue);
      expect(entry.appliesTo('lib/ui/page.dart'), isFalse);
    });
  });

  group('findBannedEntry', () {
    test('returns the first matching in-scope entry', () {
      final entries = entriesOf('''
rules:
  r:
    banned:
      - deny: [a]
        in: ['lib/ui/**']
        message: first
      - deny: [a]
        message: second
''');

      // The first entry is out of scope here, so the second one wins.
      final found = findBannedEntry(
        entries: entries,
        value: 'a',
        relativePath: 'lib/domain/x.dart',
      );
      expect(found?.message, 'second');
    });

    test('returns null when nothing matches', () {
      final entries = entriesOf('''
rules:
  r:
    banned:
      - deny: [a]
''');

      expect(
        findBannedEntry(
          entries: entries,
          value: 'b',
          relativePath: 'lib/x.dart',
        ),
        isNull,
      );
    });
  });

  group('messageSuffix', () {
    test('prefixes a space so the diagnostic reads as two sentences', () {
      final entry = entriesOf('''
rules:
  r:
    banned:
      - deny: [a]
        message: 'Use B instead.'
''').single;

      expect(messageSuffix(entry), ' Use B instead.');
    });
  });
}
