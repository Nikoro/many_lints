// ignore_for_file: implementation_imports
import 'dart:io';

import 'package:analysis_server_plugin/src/registry.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:many_lints/many_lints.dart' as many_lints;
import 'package:many_lints/many_lints.dart';
import 'package:many_lints/src/many_lints_rule.dart';
import 'package:many_lints/src/presets.dart';
import 'package:test/test.dart';

void main() {
  const removedRules = {'prefer_contains'};
  late ManyLintsPlugin plugin;
  late PluginRegistryImpl registry;

  setUp(() {
    plugin = ManyLintsPlugin();
    registry = PluginRegistryImpl('many_lints');
  });

  test('top-level plugin variable is a ManyLintsPlugin', () {
    expect(many_lints.plugin, isA<ManyLintsPlugin>());
    expect(many_lints.plugin.name, 'Many Lints');
  });

  test('plugin has correct name', () {
    expect(plugin.name, 'Many Lints');
  });

  test('register() completes without error', () {
    expect(() => plugin.register(registry), returnsNormally);
  });

  test('all rule names are unique', () {
    plugin.register(registry);

    final allNames = [
      ...registry.warningRules.keys,
      ...registry.lintRules.keys,
    ];

    final duplicates = <String>[];
    final seen = <String>{};
    for (final name in allNames) {
      if (!seen.add(name)) {
        duplicates.add(name);
      }
    }

    expect(duplicates, isEmpty, reason: 'Duplicate rule names: $duplicates');
  });

  test('expected number of active and removed rules are registered', () {
    plugin.register(registry);
    final totalRules = registry.warningRules.length + registry.lintRules.length;
    expect(totalRules, equals(197));
    expect(
      registry.warningRules.values.whereType<RemovedAnalysisRule>().map(
        (rule) => rule.name,
      ),
      unorderedEquals(removedRules),
    );
    final removed = registry.warningRules['prefer_contains']!;
    expect(removed.state.isRemoved, isTrue);
    expect(removed.state.replacedBy, 'prefer_contains');
  });

  test('rule sources, tests, docs, and examples stay in sync', () {
    plugin.register(registry);

    final registered = {
      ...registry.warningRules.keys,
      ...registry.lintRules.keys,
    }..removeAll(removedRules);
    final sources = _baseNames(Directory('lib/src/rules'), suffixes: ['.dart'])
      ..remove('AGENTS');
    final docs = _baseNames(
      Directory('docs/src/content/docs/docs/rules'),
      suffixes: ['.md', '.mdx'],
      recursive: true,
      normalizeHyphens: true,
    );
    final examples = _baseNames(
      Directory('example/lib'),
      suffixes: ['_example.dart'],
    );
    final directTests = _baseNames(Directory('test'), suffixes: ['_test.dart']);

    expect(sources, registered, reason: 'Rule source and registry drifted.');
    expect(docs, registered, reason: 'Rule documentation is incomplete.');
    expect(examples, registered, reason: 'Rule examples are incomplete.');

    const rulesCoveredBySharedTests = {
      'avoid_banned_annotations',
      'avoid_banned_exports',
      'avoid_banned_imports',
      'avoid_banned_names',
      'avoid_banned_types',
      'banned_usage',
    };
    expect(
      registered.difference(directTests),
      rulesCoveredBySharedTests,
      reason:
          'Every rule needs a same-name test file or an explicit shared-test '
          'entry.',
    );
  });

  // The prose in README.md and CLAUDE.md restates numbers that live in the
  // code: preset sizes, the rule and fix totals, the per-category breakdown,
  // and the list of assists. Nothing recomputes them, so they drift silently —
  // the README's category table went 22 rules stale (it had no fpdart row at
  // all) and its preset counts predated an entire rule family before this test
  // existed. Every claim below is parsed back out of the file and compared to
  // the registry.
  group('documentation counts match the registry', () {
    late int totalRules;
    late int totalFixes;
    late String readme;
    late String claudeMd;

    setUp(() {
      plugin.register(registry);
      totalRules =
          registry.warningRules.length +
          registry.lintRules.length -
          removedRules.length;
      totalFixes = registry.fixKinds.values.fold<int>(
        0,
        (sum, codes) => sum + codes.length,
      );
      readme = File('README.md').readAsStringSync();
      claudeMd = File('CLAUDE.md').readAsStringSync();
    });

    test('preset tables list the real preset sizes', () {
      // `none` is not derived from anything, so it is asserted as the literal
      // it is rather than looked up.
      // `opinionated` is deliberately smaller than the registry: rules that
      // contradict one already in it, and rules that do nothing unconfigured,
      // stay out of every preset. See `conflictingWithOpinionated`.
      final expected = {
        'none': 0,
        'core': coreRules.length,
        'recommended': recommendedRules.length,
        'opinionated': opinionatedRules.length,
      };

      // The docs site carries the same table, and its counts drifted silently
      // once already (31/79/156 against presets holding 37/98/162).
      final configurationPage = File(
        'docs/src/content/docs/docs/configuration.md',
      ).readAsStringSync();

      for (final (file, content) in [
        ('README.md', readme),
        ('CLAUDE.md', claudeMd),
        ('configuration.md', configurationPage),
      ]) {
        expect(
          _presetCounts(content),
          expected,
          reason: 'The preset table in $file is stale.',
        );
      }
    });

    test('README states the real rule and fix totals', () {
      final match = RegExp(
        r'(\d+) lints with (\d+) quick fixes',
      ).firstMatch(readme);

      expect(match, isNotNull, reason: 'The README lint summary is missing.');
      expect(
        (int.parse(match!.group(1)!), int.parse(match.group(2)!)),
        (totalRules, totalFixes),
        reason: 'The README lint summary is stale.',
      );
    });

    test('README category table covers every rule exactly once', () {
      // Each row links to a category directory, so the row set and the
      // directory set must match — a new category with no row would otherwise
      // only show up as a wrong total.
      final rows = <String, int>{
        for (final match in RegExp(
          r'\| \[[^\]]+\]\(https://nikoro\.github\.io/many_lints/docs/rules/'
          r'([a-z-]+)/\) \| *(\d+) \|',
        ).allMatches(readme))
          match.group(1)!: int.parse(match.group(2)!),
      };

      final directories = {
        for (final directory in Directory(
          'docs/src/content/docs/docs/rules',
        ).listSync().whereType<Directory>())
          directory.path.split(Platform.pathSeparator).last: directory
              .listSync()
              .whereType<File>()
              .length,
      };

      expect(
        rows,
        directories,
        reason: 'The README category table drifted from the rule pages.',
      );
      expect(
        rows.values.fold<int>(0, (sum, count) => sum + count),
        totalRules,
        reason: 'The README category counts do not add up to the rule total.',
      );
    });

    test('README lists every registered assist', () {
      // Assists are named in prose rather than by id, so this counts rows and
      // leaves the wording free. A count is enough: the failure it guards
      // against is adding an assist and forgetting the README, which is
      // exactly what happened to the "Do notation" one.
      final rows = RegExp(
        r'^\| \*\*[^|]+\*\* \| [^|]+ \| [^|]+ \|$',
        multiLine: true,
      ).allMatches(readme).length;

      expect(
        rows,
        registry.assistKinds.length,
        reason: 'The README assist table is missing a registered assist.',
      );
    });
  });

  test('documentation fix badges match registered quick fixes', () {
    plugin.register(registry);

    final registeredFixes = registry.fixKinds.values
        .expand((codes) => codes)
        .toSet();
    const pageSuffixes = ['.md', '.mdx'];
    final documentedFixes = <String>{
      for (final file in Directory(
        'docs/src/content/docs/docs/rules',
      ).listSync(recursive: true).whereType<File>())
        if (_matchingSuffix(file.path, pageSuffixes) case final suffix?)
          if (file.readAsStringSync().contains('rule-badge--fix'))
            _baseName(file.path, suffix: suffix, normalizeHyphens: true),
    };

    expect(
      documentedFixes,
      registeredFixes,
      reason: 'A Fix badge must describe a quick fix registered for the rule.',
    );
  });

  test('every registered quick fix has an end-to-end output test', () {
    plugin.register(registry);

    final registeredFixes = registry.fixKinds.values
        .expand((codes) => codes)
        .toSet();
    final outputTestFiles = <File>[
      File('test/plugin_fix_output_test.dart'),
      ...Directory(
        'test/fix_output',
      ).listSync(recursive: true).whereType<File>(),
    ];
    final testedFixes = <String>{};
    final groupPattern = RegExp(r"group\('([a-z0-9_]+)'");
    for (final file in outputTestFiles) {
      if (!file.path.endsWith('.dart')) continue;
      for (final match in groupPattern.allMatches(file.readAsStringSync())) {
        testedFixes.add(match.group(1)!);
      }
    }

    expect(
      testedFixes,
      registeredFixes,
      reason:
          'Every registered fix needs a real PluginServer output test, and '
          'stale fix groups must be removed.',
    );
  });

  test('fixes are registered', () {
    plugin.register(registry);
    final totalFixes = registry.fixKinds.values.fold<int>(
      0,
      (sum, v) => sum + v.length,
    );
    expect(totalFixes, equals(99));
  });

  test('assists are registered', () {
    plugin.register(registry);

    // Assert the ids rather than the count: a missing `registerAssist` is
    // invisible to an assist's own tests when they construct it directly, and
    // a bare count says only that the number changed, not which one is gone.
    expect(
      registry.assistKinds.map((kind) => kind.id),
      unorderedEquals([
        'many_lints.assist.convertDoNotationToFlatMap',
        'many_lints.assist.convertFlatMapToDoNotation',
        'many_lints.assist.convertIterableMapToCollectionFor',
        'many_lints.assist.convertNullCheckToPattern',
        'many_lints.assist.inlineNullCheckIntoPattern',
        'many_lints.assist.convertToLazyFpdartType',
        'many_lints.assist.convertTryCatchConstructorToTryStatement',
      ]),
    );
  });

  // Per-rule `exclude` is applied by `ManyLintsRule`, so a rule that extends
  // `AnalysisRule` directly silently ignores every `exclude` a user writes for
  // it. Nothing else fails in that case — the rule's own tests never configure
  // an exclude — so the invariant is asserted here instead.
  test('every registered rule extends ManyLintsRule', () {
    plugin.register(registry);

    final offenders =
        [...registry.warningRules.values, ...registry.lintRules.values]
            .where(
              (rule) => rule is! ManyLintsRule && rule is! RemovedAnalysisRule,
            )
            .map((rule) => rule.name)
            .toList();

    expect(
      offenders,
      isEmpty,
      reason:
          'These rules do not extend ManyLintsRule, so per-rule `exclude` '
          'would be ignored for them: $offenders',
    );
  });
}

/// The preset sizes claimed by a Markdown preset table, keyed by preset name.
///
/// Both README.md and CLAUDE.md carry the same table with different prose in
/// the last column, so only the first two columns are matched.
Map<String, int> _presetCounts(String content) => {
  for (final match in RegExp(
    r'^\| `(none|core|recommended|opinionated)` \| *(\d+) \|',
    multiLine: true,
  ).allMatches(content))
    match.group(1)!: int.parse(match.group(2)!),
};

/// The base names of every file in [directory] ending in one of [suffixes].
///
/// [suffixes] is a list because a rule page is `.md` or `.mdx` depending on
/// whether the rule takes options — a configurable rule shows its snippets in
/// both config locations via Starlight tabs, which needs MDX. Matching only
/// `.md` silently skipped all 52 configurable rules, so this test compared a
/// 104-entry set against the full registry and could never pass.
///
/// The longest matching suffix wins, so `.mdx` is stripped as `.mdx` rather
/// than leaving a trailing `.` behind from a shorter `.md` match.
Set<String> _baseNames(
  Directory directory, {
  required List<String> suffixes,
  bool recursive = false,
  bool normalizeHyphens = false,
}) => {
  for (final file in directory.listSync(recursive: recursive).whereType<File>())
    if (_matchingSuffix(file.path, suffixes) case final suffix?)
      _baseName(file.path, suffix: suffix, normalizeHyphens: normalizeHyphens),
};

/// The longest entry of [suffixes] that [path] ends with, or `null` for none.
String? _matchingSuffix(String path, List<String> suffixes) {
  String? longest;
  for (final suffix in suffixes) {
    if (!path.endsWith(suffix)) continue;
    if (longest == null || suffix.length > longest.length) longest = suffix;
  }
  return longest;
}

String _baseName(
  String path, {
  required String suffix,
  bool normalizeHyphens = false,
}) {
  final fileName = path.split(Platform.pathSeparator).last;
  final name = fileName.substring(0, fileName.length - suffix.length);
  return normalizeHyphens ? name.replaceAll('-', '_') : name;
}
