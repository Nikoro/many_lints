// ignore_for_file: implementation_imports
import 'dart:async';

import 'package:analysis_server_plugin/src/plugin_server.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_constants.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as protocol;
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart'
    as protocol;
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:many_lints/many_lints.dart';
import 'package:many_lints/src/rule_config.dart';
import 'package:test/test.dart';

/// A catch clause containing only `rethrow`, which `avoid_only_rethrow`
/// reports. Pure Dart, so it needs no Flutter types to resolve.
const _rethrowCode = '''
void doSomething() {}

void main() {
  try {
    doSomething();
  } catch (e) {
    rethrow;
  }
}
''';

/// Triggers `prefer_type_over_var` from all three of the callbacks it
/// registers — a top-level declaration, a local statement, and a `for` loop.
///
/// A rule that guards only some of its entry points still reports from the
/// unguarded ones, so exclusion has to silence all three at once.
const _varCode = '''
var topLevel = 1;

void main() {
  var local = 2;
  for (var i = 0; i < 3; i++) {
    print(i);
    print(local);
  }
  print(topLevel);
}
''';

/// Commented-out code, which `avoid_commented_out_code` reports from an
/// `addCompilationUnit` callback rather than a per-node one.
const _commentedOutCode = '''
void main() {
  // print('hello');
  // var x = 1;
}
''';

/// A `!` on a field an enclosing `if (field != null)` already checked, which
/// `avoid_non_null_assertion` reports unless `ignore_checked_fields` is set.
const _checkedFieldBangCode = '''
class C {
  String? field;

  void f() {
    if (field != null) {
      print(field!.length);
    }
  }
}
''';

/// A `!` with no null check guarding it, which no option exempts.
const _unguardedBangCode = '''
class C {
  String? field;

  void f() {
    print(field!.length);
  }
}
''';

/// The conventional map-index bang is exempt below pedantic, but the strictest
/// preset bans every postfix null assertion.
const _mapBangCode = '''
void f(Map<String, String> values) {
  print(values['key']!.length);
}
''';

/// The same, but with a typed `on ... catch` clause.
const _typedRethrowCode = '''
void doSomething() {}

void main() {
  try {
    doSomething();
  } on StateError catch (e) {
    rethrow;
  }
}
''';

void main() {
  group('ManyLintsConfig.parse', () {
    test('parses exclude patterns and free-form options', () {
      final config = ManyLintsConfig.parse('''
rules:
  avoid_border_all:
    exclude:
      - test/**
      - "**/*.g.dart"
    only_const_context: true
    max_count: 3
    names:
      - a
      - b
''');

      final rule = config.forRule('avoid_border_all');
      expect(rule.exclude, ['test/**', '**/*.g.dart']);
      expect(
        rule.boolOption('only_const_context', defaultValue: false),
        isTrue,
      );
      expect(rule.intOption('max_count', defaultValue: 0), 3);
      expect(rule.stringListOption('names'), ['a', 'b']);
    });

    test('returns defaults for absent rules and options', () {
      final config = ManyLintsConfig.parse('rules:\n  other_rule:\n    x: 1\n');

      final rule = config.forRule('avoid_border_all');
      expect(rule.exclude, isEmpty);
      expect(rule.boolOption('only_const_context', defaultValue: true), isTrue);
      expect(rule.intOption('missing', defaultValue: 7), 7);
    });

    test('returns defaults when an option has the wrong type', () {
      final config = ManyLintsConfig.parse('''
rules:
  avoid_border_all:
    only_const_context: "not a bool"
''');

      final rule = config.forRule('avoid_border_all');
      expect(
        rule.boolOption('only_const_context', defaultValue: false),
        isFalse,
      );
    });

    test('parses include patterns and a message', () {
      final config = ManyLintsConfig.parse('''
rules:
  avoid_border_all:
    include:
      - lib/ui/**
    message: Use AppBorder.
''');

      final rule = config.forRule('avoid_border_all');
      expect(rule.include, ['lib/ui/**']);
      expect(rule.message, 'Use AppBorder.');
    });

    test('include and message are not exposed as free-form options', () {
      final config = ManyLintsConfig.parse('''
rules:
  avoid_border_all:
    include: [lib/**]
    message: hi
''');

      // They are structural, like `exclude` — leaking them into `options`
      // would let a rule read `include` as if it were its own option.
      final rule = config.forRule('avoid_border_all');
      expect(rule.options.keys, isEmpty);
    });

    test('a bare scalar include becomes a one-item list', () {
      final config = ManyLintsConfig.parse('''
rules:
  avoid_border_all:
    include: lib/ui/**
''');

      expect(config.forRule('avoid_border_all').include, ['lib/ui/**']);
    });

    // `exclude` gained scalar support alongside `include`, so the two spell
    // the same idea the same way.
    test('a bare scalar exclude becomes a one-item list', () {
      final config = ManyLintsConfig.parse('''
rules:
  avoid_border_all:
    exclude: lib/legacy.dart
''');

      expect(config.forRule('avoid_border_all').exclude, ['lib/legacy.dart']);
    });

    test('a list exclude still parses as before', () {
      final config = ManyLintsConfig.parse('''
rules:
  avoid_border_all:
    exclude: [a.dart, b.dart]
''');

      expect(config.forRule('avoid_border_all').exclude, ['a.dart', 'b.dart']);
    });

    test('a blank message is dropped', () {
      final config = ManyLintsConfig.parse('''
rules:
  avoid_border_all:
    message: "   "
''');

      expect(config.forRule('avoid_border_all').message, isNull);
    });

    test('a wrong-typed include yields an empty list', () {
      final config = ManyLintsConfig.parse('''
rules:
  avoid_border_all:
    include: 42
''');

      expect(config.forRule('avoid_border_all').include, isEmpty);
    });

    test('malformed yaml degrades to empty instead of throwing', () {
      final config = ManyLintsConfig.parse('rules: [unclosed');
      expect(config.forRule('avoid_border_all').exclude, isEmpty);
    });

    test('non-map document degrades to empty', () {
      expect(
        ManyLintsConfig.parse('just a string').forRule('x').exclude,
        isEmpty,
      );
    });
  });

  group('ManyLintsConfig.parseOptionsFile', () {
    test('reads rules nested under the many_lints section', () {
      final config = ManyLintsConfig.parseOptionsFile('''
analyzer:
  exclude:
    - build/**

many_lints:
  rules:
    avoid_only_rethrow:
      exclude:
        - test/**
      ignore_typed_catches: true
''');

      final rule = config.forRule('avoid_only_rethrow');
      expect(rule.exclude, ['test/**']);
      expect(
        rule.boolOption('ignore_typed_catches', defaultValue: false),
        isTrue,
      );
    });

    test('yields empty when the many_lints section is absent', () {
      final config = ManyLintsConfig.parseOptionsFile('''
analyzer:
  exclude:
    - build/**
''');

      expect(config.forRule('avoid_only_rethrow').exclude, isEmpty);
    });

    test('ignores a root-level rules key without the section', () {
      // `rules:` at the document root belongs to many_lints.yaml, not to
      // analysis_options.yaml, and must not be picked up here.
      final config = ManyLintsConfig.parseOptionsFile('''
rules:
  avoid_only_rethrow:
    exclude:
      - test/**
''');

      expect(config.forRule('avoid_only_rethrow').exclude, isEmpty);
    });
  });

  group('end-to-end through PluginServer', () {
    late _ConfigHarness harness;

    setUp(() async {
      ConfigLoader.clearCache();
      harness = _ConfigHarness();
      await harness.setUp();
    });

    tearDown(() async => harness.tearDown());

    // Rules are opt-in as of 1.0.0: with no configuration at all the package
    // is silent, so installing it never floods an existing codebase.
    test('reports nothing when no config file exists', () async {
      final errors = await harness.analyze(_rethrowCode);

      expect(errors.map((e) => e.code), isNot(contains('avoid_only_rethrow')));
    });

    test('a preset alone enables the rule', () async {
      final errors = await harness.analyze(
        _rethrowCode,
        config: 'preset: recommended',
      );

      expect(errors.map((e) => e.code), contains('avoid_only_rethrow'));
    });

    // Configuring a rule is itself a statement that the rule is wanted, so an
    // `exclude:` or an option does not silently do nothing without a preset.
    test('a config block alone enables the rule', () async {
      final errors = await harness.analyze(
        _typedRethrowCode,
        config: '''
rules:
  avoid_only_rethrow:
    ignore_typed_catches: false
''',
      );

      expect(errors.map((e) => e.code), contains('avoid_only_rethrow'));
    });

    // A glob is not required: an exact path is a valid pattern, which is the
    // form users reach for first when silencing a single file.
    test('an exact file path with no glob excludes that file', () async {
      final errors = await harness.analyze(
        _rethrowCode,
        fileName: 'legacy.dart',
        config: '''
rules:
  avoid_only_rethrow:
    exclude:
      - lib/legacy.dart
''',
      );

      expect(errors.map((e) => e.code), isNot(contains('avoid_only_rethrow')));
    });

    test('an exact file path does not affect a different file', () async {
      final errors = await harness.analyze(
        _rethrowCode,
        fileName: 'other.dart',
        config: '''
rules:
  avoid_only_rethrow:
    exclude:
      - lib/legacy.dart
''',
      );

      expect(errors.map((e) => e.code), contains('avoid_only_rethrow'));
    });

    test('exclude lists apply per rule, not across rules', () async {
      final errors = await harness.analyze(
        '''
$_rethrowCode

class StillLinted {
  // final retries = 3;

  void another() {}
}
''',
        // `preset: opinionated` so that the rule which must *keep* reporting is on
        // without needing a config block of its own — a block would itself
        // opt the rule in and blunt what this test checks.
        config: '''
preset: opinionated
rules:
  avoid_only_rethrow:
    exclude:
      - lib/**
''',
      );

      final codes = errors.map((e) => e.code);
      expect(codes, isNot(contains('avoid_only_rethrow')));
      // Excluding one rule leaves every other rule running on the same file.
      expect(codes, contains('avoid_commented_out_code'));
    });

    test('exclude pattern silences the rule in a matching file', () async {
      final errors = await harness.analyze(
        _rethrowCode,
        config: '''
rules:
  avoid_only_rethrow:
    exclude:
      - lib/**
''',
      );

      expect(errors.map((e) => e.code), isNot(contains('avoid_only_rethrow')));
    });

    test('exclude pattern for another directory leaves the rule on', () async {
      final errors = await harness.analyze(
        _rethrowCode,
        config: '''
rules:
  avoid_only_rethrow:
    exclude:
      - test/**
''',
      );

      expect(errors.map((e) => e.code), contains('avoid_only_rethrow'));
    });

    test('suffix glob excludes generated files', () async {
      final errors = await harness.analyze(
        _rethrowCode,
        fileName: 'widget.g.dart',
        config: '''
rules:
  avoid_only_rethrow:
    exclude:
      - "**/*.g.dart"
''',
      );

      expect(errors.map((e) => e.code), isNot(contains('avoid_only_rethrow')));
    });

    test('exclude for one rule does not disable another rule', () async {
      final errors = await harness.analyze(
        '''
$_rethrowCode

class Base {
  @override
  bool operator ==(Object other) => true;
  @override
  int get hashCode => 0;
}

class Child extends Base {
  @override
  bool operator ==(Object other) => true;
}
''',
        config: '''
preset: opinionated
rules:
  avoid_only_rethrow:
    exclude:
      - lib/**
''',
      );

      final codes = errors.map((e) => e.code);
      expect(codes, isNot(contains('avoid_only_rethrow')));
      expect(codes, contains('prefer_overriding_parent_equality'));
    });

    // `ManyLintsRule` suppresses diagnostics at the reporter rather than in
    // each visitor, so exclusion should hold whatever shape a rule's visitor
    // has. These cover one rule per shape in the package.
    test(
      'exclude silences every callback of a multi-registration rule',
      () async {
        final errors = await harness.analyze(
          _varCode,
          config: '''
rules:
  prefer_type_over_var:
    exclude:
      - lib/**
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('prefer_type_over_var')),
        );
      },
    );

    test(
      'a multi-registration rule reports from each of its callbacks',
      () async {
        final errors = await harness.analyze(
          _varCode,
          config: 'preset: opinionated',
        );

        // Asymmetric positive: without the exclusion the same source reports
        // three times, so the test above cannot pass by reporting nothing.
        final offsets = errors
            .where((e) => e.code == 'prefer_type_over_var')
            .map((e) => e.location.offset)
            .toSet();
        expect(offsets, hasLength(3));
      },
    );

    test('exclude silences a compilation-unit rule', () async {
      final errors = await harness.analyze(
        _commentedOutCode,
        config: '''
rules:
  avoid_commented_out_code:
    exclude:
      - lib/**
''',
      );

      expect(
        errors.map((e) => e.code),
        isNot(contains('avoid_commented_out_code')),
      );
    });

    test('a compilation-unit rule reports without the exclusion', () async {
      final errors = await harness.analyze(
        _commentedOutCode,
        config: 'preset: opinionated',
      );

      expect(errors.map((e) => e.code), contains('avoid_commented_out_code'));
    });

    test(
      'exclude applies to the file being analyzed, not the whole run',
      () async {
        final excluded = await harness.analyze(
          _varCode,
          fileName: 'generated.g.dart',
          config: '''
rules:
  prefer_type_over_var:
    exclude:
      - "**/*.g.dart"
''',
        );

        expect(
          excluded.map((e) => e.code),
          isNot(contains('prefer_type_over_var')),
        );
      },
    );

    test('mode option narrows what the rule reports', () async {
      final errors = await harness.analyze(
        _typedRethrowCode,
        config: '''
rules:
  avoid_only_rethrow:
    ignore_typed_catches: true
''',
      );

      expect(errors.map((e) => e.code), isNot(contains('avoid_only_rethrow')));
    });

    test('mode option leaves the default behaviour untouched', () async {
      final errors = await harness.analyze(
        _typedRethrowCode,
        config: 'preset: opinionated',
      );

      expect(errors.map((e) => e.code), contains('avoid_only_rethrow'));
    });

    test('mode option still reports the cases it does not exempt', () async {
      final errors = await harness.analyze(
        _rethrowCode,
        config: '''
rules:
  avoid_only_rethrow:
    ignore_typed_catches: true
''',
      );

      expect(errors.map((e) => e.code), contains('avoid_only_rethrow'));
    });

    group('avoid_non_null_assertion.ignore_checked_fields', () {
      test('the rule reports a checked field by default', () async {
        final errors = await harness.analyze(
          _checkedFieldBangCode,
          config: 'preset: opinionated',
        );

        expect(errors.map((e) => e.code), contains('avoid_non_null_assertion'));
      });

      test('the option exempts a bang guarded by a null check', () async {
        final errors = await harness.analyze(
          _checkedFieldBangCode,
          config: '''
rules:
  avoid_non_null_assertion:
    ignore_checked_fields: true
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('avoid_non_null_assertion')),
        );
      });

      // Asymmetric counterpart: the option must not silence an unguarded bang,
      // or "the option worked" is indistinguishable from "the rule never ran".
      test('the option still reports an unguarded bang', () async {
        final errors = await harness.analyze(
          _unguardedBangCode,
          config: '''
rules:
  avoid_non_null_assertion:
    ignore_checked_fields: true
''',
        );

        expect(errors.map((e) => e.code), contains('avoid_non_null_assertion'));
      });

      test('a wrong-typed option value falls back to the default', () async {
        final errors = await harness.analyze(
          _checkedFieldBangCode,
          config: '''
preset: opinionated
rules:
  avoid_non_null_assertion:
    ignore_checked_fields: "not a bool"
''',
        );

        expect(errors.map((e) => e.code), contains('avoid_non_null_assertion'));
      });
    });

    group('avoid_non_null_assertion.ignore_map_indexes', () {
      test('the default keeps the idiomatic map-index exemption', () async {
        final errors = await harness.analyze(
          _mapBangCode,
          config: 'preset: opinionated',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('avoid_non_null_assertion')),
        );
      });

      test('pedantic bans the map-index bang too', () async {
        final errors = await harness.analyze(
          _mapBangCode,
          config: 'preset: pedantic',
        );

        expect(errors.map((e) => e.code), contains('avoid_non_null_assertion'));
      });
    });

    test('analysis_options section configures the rule', () async {
      final errors = await harness.analyze(
        _rethrowCode,
        optionsSection: '''
many_lints:
  rules:
    avoid_only_rethrow:
      exclude:
        - lib/**
''',
      );

      expect(errors.map((e) => e.code), isNot(contains('avoid_only_rethrow')));
    });

    test('analysis_options section is not applied to other paths', () async {
      final errors = await harness.analyze(
        _rethrowCode,
        optionsSection: '''
many_lints:
  rules:
    avoid_only_rethrow:
      exclude:
        - test/**
''',
      );

      expect(errors.map((e) => e.code), contains('avoid_only_rethrow'));
    });

    test('a custom top-level section provokes no analyzer warning', () async {
      final errors = await harness.analyze(
        _rethrowCode,
        optionsSection: '''
many_lints:
  rules:
    avoid_only_rethrow:
      exclude:
        - test/**
''',
      );

      // The analyzer only validates the interior of sections it knows, so an
      // unrecognized top-level key must not yield `unsupported_option`.
      expect(errors.map((e) => e.code), isNot(contains('unsupported_option')));
    });

    group('include', () {
      test('limits the rule to matching paths', () async {
        final errors = await harness.analyze(
          _rethrowCode,
          fileName: 'feature/a.dart',
          config: '''
rules:
  avoid_only_rethrow:
    include:
      - lib/feature/**
''',
        );

        expect(errors.map((e) => e.code), contains('avoid_only_rethrow'));
      });

      // The asymmetric half: without this, the test above could pass purely
      // because the rule fires everywhere and `include` does nothing.
      test('silences the rule outside matching paths', () async {
        final errors = await harness.analyze(
          _rethrowCode,
          fileName: 'other/a.dart',
          config: '''
rules:
  avoid_only_rethrow:
    include:
      - lib/feature/**
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('avoid_only_rethrow')),
        );
      });

      test('an empty include list means everywhere, not nowhere', () async {
        final errors = await harness.analyze(
          _rethrowCode,
          config: '''
preset: opinionated
rules:
  avoid_only_rethrow:
    include: []
''',
        );

        expect(errors.map((e) => e.code), contains('avoid_only_rethrow'));
      });

      test('accepts a bare scalar as a one-item list', () async {
        final errors = await harness.analyze(
          _rethrowCode,
          fileName: 'feature/a.dart',
          config: '''
rules:
  avoid_only_rethrow:
    include: lib/feature/**
''',
        );

        expect(errors.map((e) => e.code), contains('avoid_only_rethrow'));
      });

      test('exclude wins over include for a file matching both', () async {
        final errors = await harness.analyze(
          _rethrowCode,
          fileName: 'feature/generated.dart',
          config: '''
rules:
  avoid_only_rethrow:
    include:
      - lib/feature/**
    exclude:
      - "**/generated.dart"
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('avoid_only_rethrow')),
        );
      });

      test('a wrong-typed include does not disable the rule', () async {
        final errors = await harness.analyze(
          _rethrowCode,
          config: '''
preset: opinionated
rules:
  avoid_only_rethrow:
    include: 42
''',
        );

        expect(errors.map((e) => e.code), contains('avoid_only_rethrow'));
      });
    });

    group('message', () {
      test('appends the configured sentence to the diagnostic', () async {
        final errors = await harness.analyze(
          _rethrowCode,
          config: '''
rules:
  avoid_only_rethrow:
    message: Use our AppError helper instead.
''',
        );

        final error = errors.firstWhere((e) => e.code == 'avoid_only_rethrow');
        expect(error.message, endsWith('Use our AppError helper instead.'));
        // The original text must survive — appending, not replacing.
        expect(error.message, contains('rethrow'));
      });

      test('leaves the message alone when unset', () async {
        final errors = await harness.analyze(
          _rethrowCode,
          config: 'preset: opinionated',
        );

        final error = errors.firstWhere((e) => e.code == 'avoid_only_rethrow');
        expect(error.message, isNot(contains('AppError')));
      });

      test(
        'keeps the diagnostic code so ignores and fixes still work',
        () async {
          final errors = await harness.analyze(
            _rethrowCode,
            config: '''
rules:
  avoid_only_rethrow:
    message: House rule.
''',
          );

          expect(errors.map((e) => e.code), contains('avoid_only_rethrow'));
        },
      );

      test('an empty message is treated as absent', () async {
        final errors = await harness.analyze(
          _rethrowCode,
          config: '''
preset: opinionated
rules:
  avoid_only_rethrow:
    message: "   "
''',
        );

        final error = errors.firstWhere((e) => e.code == 'avoid_only_rethrow');
        // No trailing separator from an empty suffix.
        expect(error.message.trimRight(), error.message);
      });

      test('applies to a rule reporting from several callbacks', () async {
        final errors = await harness.analyze(
          _varCode,
          config: '''
rules:
  prefer_type_over_var:
    message: See the style guide.
''',
        );

        final reported = errors.where((e) => e.code == 'prefer_type_over_var');
        expect(reported, isNotEmpty);
        expect(
          reported.every((e) => e.message.endsWith('See the style guide.')),
          isTrue,
          reason: 'every callback must go through the same reporter seam',
        );
      });
    });

    group('double_literal_format options', () {
      const trailingZeroCode = 'const x = 0.50;\n';
      const missingLeadingZeroCode = 'const x = .5;\n';

      test('both defects are reported with no options set', () async {
        final trailing = await harness.analyze(
          trailingZeroCode,
          config: 'rules:\n  double_literal_format: true\n',
        );
        final leading = await harness.analyze(
          missingLeadingZeroCode,
          config: 'rules:\n  double_literal_format: true\n',
          fileName: 'leading.dart',
        );

        expect(trailing.map((e) => e.code), contains('double_literal_format'));
        expect(leading.map((e) => e.code), contains('double_literal_format'));
      });

      test('trailing_zero: false silences the trailing-zero case', () async {
        final errors = await harness.analyze(
          trailingZeroCode,
          config: '''
rules:
  double_literal_format:
    trailing_zero: false
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('double_literal_format')),
        );
      });

      // Asymmetric counterpart: turning one defect off must leave the other
      // reporting, or silence cannot be told from the rule never running.
      test(
        'trailing_zero: false still reports a missing leading zero',
        () async {
          final errors = await harness.analyze(
            missingLeadingZeroCode,
            config: '''
rules:
  double_literal_format:
    trailing_zero: false
''',
          );

          expect(errors.map((e) => e.code), contains('double_literal_format'));
        },
      );

      test(
        'leading_zero: false still reports a redundant leading zero',
        () async {
          final errors = await harness.analyze(
            'const x = 00.5;\n',
            config: '''
rules:
  double_literal_format:
    leading_zero: false
''',
          );

          expect(errors.map((e) => e.code), contains('double_literal_format'));
        },
      );
    });

    group('avoid_inconsistent_digit_separators options', () {
      test('group_size changes which grouping is accepted', () async {
        final errors = await harness.analyze(
          'const x = 1_000_000;\n',
          config: '''
rules:
  avoid_inconsistent_digit_separators:
    group_size: 4
''',
        );

        expect(
          errors.map((e) => e.code),
          contains('avoid_inconsistent_digit_separators'),
        );
      });

      test('the same literal passes under the default group size', () async {
        final errors = await harness.analyze(
          'const x = 1_000_000;\n',
          config: 'rules:\n  avoid_inconsistent_digit_separators: true\n',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('avoid_inconsistent_digit_separators')),
        );
      });

      test('group_size: 0 accepts any consistent grouping', () async {
        final errors = await harness.analyze(
          'const x = 12_3456_7890;\n',
          config: '''
rules:
  avoid_inconsistent_digit_separators:
    group_size: 0
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('avoid_inconsistent_digit_separators')),
        );
      });

      test('group_size: 0 still reports an inconsistent grouping', () async {
        final errors = await harness.analyze(
          'const x = 1_23_456;\n',
          config: '''
rules:
  avoid_inconsistent_digit_separators:
    group_size: 0
''',
        );

        expect(
          errors.map((e) => e.code),
          contains('avoid_inconsistent_digit_separators'),
        );
      });
    });

    group('prefer_early_return.min_statements', () {
      const threeStatementCode = '''
void f(bool ok) {
  if (ok) {
    print(1);
    print(2);
    print(3);
  }
}
''';

      test('three statements report at the default threshold', () async {
        final errors = await harness.analyze(
          threeStatementCode,
          config: 'rules:\n  prefer_early_return: true\n',
        );

        expect(errors.map((e) => e.code), contains('prefer_early_return'));
      });

      test('raising the threshold silences them', () async {
        final errors = await harness.analyze(
          threeStatementCode,
          config: '''
rules:
  prefer_early_return:
    min_statements: 4
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('prefer_early_return')),
        );
      });

      // Asymmetric counterpart: the raised threshold must still report a body
      // that clears it, or silence proves nothing.
      test('a longer body still reports at the raised threshold', () async {
        final errors = await harness.analyze(
          '''
void f(bool ok) {
  if (ok) {
    print(1);
    print(2);
    print(3);
    print(4);
  }
}
''',
          config: '''
rules:
  prefer_early_return:
    min_statements: 4
''',
        );

        expect(errors.map((e) => e.code), contains('prefer_early_return'));
      });
    });

    group('avoid_negated_conditions.report_not_equal', () {
      const notEqualCode = '''
void f(int a, int b) {
  if (a != b) {
    print(1);
  } else {
    print(2);
  }
}
''';

      test('a not-equal condition reports by default', () async {
        final errors = await harness.analyze(
          notEqualCode,
          config: 'rules:\n  avoid_negated_conditions: true\n',
        );

        expect(errors.map((e) => e.code), contains('avoid_negated_conditions'));
      });

      test('report_not_equal: false silences it', () async {
        final errors = await harness.analyze(
          notEqualCode,
          config: '''
rules:
  avoid_negated_conditions:
    report_not_equal: false
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('avoid_negated_conditions')),
        );
      });

      // Asymmetric counterpart: a bang is still a negation with the option off.
      test('report_not_equal: false still reports a bang', () async {
        final errors = await harness.analyze(
          '''
void f(bool ok) {
  if (!ok) {
    print(1);
  } else {
    print(2);
  }
}
''',
          config: '''
rules:
  avoid_negated_conditions:
    report_not_equal: false
''',
        );

        expect(errors.map((e) => e.code), contains('avoid_negated_conditions'));
      });
    });

    group('precedence when both sources exist', () {
      test('many_lints.yaml wins over the analysis_options section', () async {
        final errors = await harness.analyze(
          _rethrowCode,
          // The dedicated file excludes this file...
          config: '''
rules:
  avoid_only_rethrow:
    exclude:
      - lib/**
''',
          // ...while the options section would not have.
          optionsSection: '''
many_lints:
  rules:
    avoid_only_rethrow:
      exclude:
        - test/**
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('avoid_only_rethrow')),
        );
      });

      test('the losing source is ignored outright, not merged', () async {
        final errors = await harness.analyze(
          _rethrowCode,
          // The dedicated file exists but excludes nothing relevant, so the
          // rule must report — proving the options section's `lib/**` was
          // discarded rather than merged in.
          config: '''
rules:
  avoid_only_rethrow:
    exclude:
      - test/**
''',
          optionsSection: '''
many_lints:
  rules:
    avoid_only_rethrow:
      exclude:
        - lib/**
''',
        );

        expect(errors.map((e) => e.code), contains('avoid_only_rethrow'));
      });
    });
  });
}

class _ConfigHarness with ResourceProviderMixin {
  final channel = _FakeChannel();

  late final PluginServer pluginServer;

  String get byteStoreRoot => convertPath('/byteStore');

  String get packagePath => convertPath('/package');

  String get sdkRoot => convertPath('/sdk');

  /// Analyzes [content], optionally writing configuration to either source.
  ///
  /// [config] is written to `many_lints.yaml`; [optionsSection] is written as
  /// a top-level `many_lints:` section inside `analysis_options.yaml`. Passing
  /// both exercises the precedence rule.
  Future<List<protocol.AnalysisError>> analyze(
    String content, {
    String? config,
    String? optionsSection,
    String fileName = 'test.dart',
  }) async {
    final filePath = join(packagePath, 'lib', fileName);

    newAnalysisOptionsYamlFile(packagePath, '''
plugins:
  many_lints:
    path: /many_lints
${optionsSection ?? ''}''');

    if (config != null) {
      newFile(join(packagePath, ConfigLoader.fileName), config);
    }
    newFile(filePath, content);

    final errors = channel.notifications
        .where((n) => n.event == protocol.ANALYSIS_NOTIFICATION_ERRORS)
        .map(protocol.AnalysisErrorsParams.fromNotification)
        .where((params) => params.file == filePath)
        .map((params) => params.errors)
        .first;

    await channel.sendRequest(
      protocol.AnalysisSetAnalysisRootsParams([packagePath], []),
    );

    return errors.timeout(const Duration(seconds: 10));
  }

  Future<void> setUp() async {
    createMockSdk(resourceProvider: resourceProvider, root: getFolder(sdkRoot));

    pluginServer = PluginServer.new2(
      resourceProvider: resourceProvider,
      plugins: {'many_lints': ManyLintsPlugin()},
    );

    await pluginServer.initialize();
    pluginServer.start(channel);
    await pluginServer.handlePluginVersionCheck(
      protocol.PluginVersionCheckParams(byteStoreRoot, sdkRoot, '0.0.1'),
    );
  }

  Future<void> tearDown() async {
    await pluginServer.waitForIdle();
    channel.close();
  }
}

class _FakeChannel implements PluginCommunicationChannel {
  final _completers = <String, Completer<protocol.Response>>{};
  final _notificationsController =
      StreamController<protocol.Notification>.broadcast();

  void Function(protocol.Request)? _onRequest;
  int _idCounter = 0;

  Stream<protocol.Notification> get notifications =>
      _notificationsController.stream;

  @override
  void close() {
    _notificationsController.close();
  }

  @override
  void listen(
    void Function(protocol.Request request)? onRequest, {
    void Function()? onDone,
    Function? onError,
    Function? onNotification,
  }) {
    _onRequest = onRequest;
  }

  @override
  void sendNotification(protocol.Notification notification) {
    if (_notificationsController.isClosed) return;
    _notificationsController.add(notification);
  }

  Future<protocol.Response> sendRequest(protocol.RequestParams params) {
    final onRequest = _onRequest;
    if (onRequest == null) {
      fail('Plugin channel has not started listening.');
    }

    final id = (_idCounter++).toString();
    final request = params.toRequest(id);
    final completer = Completer<protocol.Response>();
    _completers[request.id] = completer;
    onRequest(request);
    return completer.future;
  }

  @override
  void sendResponse(protocol.Response response) {
    _completers.remove(response.id)?.complete(response);
  }
}
