import 'package:many_lints/src/disposal_utils.dart';
import 'package:many_lints/src/rule_config.dart';
import 'package:test/test.dart';

void main() {
  group('resolveCleanupMethodsFromConfig', () {
    test('uses the defaults when cleanup_methods is absent', () {
      expect(resolveCleanupMethodsFromConfig(RuleConfig.empty), cleanupMethods);
    });

    test('replaces the defaults', () {
      const config = RuleConfig(
        options: {
          'cleanup_methods': ['release'],
        },
      );

      expect(resolveCleanupMethodsFromConfig(config), ['release']);
    });

    test('honours an explicitly empty replacement', () {
      const config = RuleConfig(options: {'cleanup_methods': <Object>[]});

      expect(resolveCleanupMethodsFromConfig(config), isEmpty);
    });

    test('falls back for a wrongly typed replacement', () {
      const config = RuleConfig(options: {'cleanup_methods': 'release'});

      expect(resolveCleanupMethodsFromConfig(config), cleanupMethods);
    });

    test('extends the defaults', () {
      const config = RuleConfig(
        options: {
          'additional_cleanup_methods': ['release'],
        },
      );

      expect(resolveCleanupMethodsFromConfig(config), [
        ...cleanupMethods,
        'release',
      ]);
    });

    test('extends a replacement', () {
      const config = RuleConfig(
        options: {
          'cleanup_methods': ['shutdown'],
          'additional_cleanup_methods': ['release'],
        },
      );

      expect(resolveCleanupMethodsFromConfig(config), ['shutdown', 'release']);
    });

    test('drops non-string list entries', () {
      const config = RuleConfig(
        options: {
          'cleanup_methods': ['shutdown', 1, true],
        },
      );

      expect(resolveCleanupMethodsFromConfig(config), ['shutdown']);
    });
  });
}
