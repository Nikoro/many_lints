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
  const removedRules = {
    'avoid_unnecessary_overrides_in_state',
    'prefer_contains',
  };
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
    expect(totalRules, equals(253));
    expect(
      registry.warningRules.values.whereType<RemovedAnalysisRule>().map(
        (rule) => rule.name,
      ),
      unorderedEquals(removedRules),
    );
    final removed = registry.warningRules['prefer_contains']!;
    expect(removed.state.isRemoved, isTrue);
    expect(removed.state.replacedBy, 'prefer_contains');
    final removedStateRule =
        registry.warningRules['avoid_unnecessary_overrides_in_state']!;
    expect(removedStateRule.state.isRemoved, isTrue);
    expect(removedStateRule.state.replacedBy, 'unnecessary_overrides');
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
        'pedantic': pedanticRules.length,
      };

      // The docs site carries the same table, and its counts drifted silently
      // once already (31/79/156 against presets holding 37/98/162).
      final configurationPage = File(
        'docs/src/content/docs/docs/configuration.mdx',
      ).readAsStringSync();

      for (final (file, content) in [
        ('README.md', readme),
        ('CLAUDE.md', claudeMd),
        ('configuration.mdx', configurationPage),
      ]) {
        expect(
          _presetCounts(content),
          expected,
          reason: 'The preset table in $file is stale.',
        );
      }

      final gettingStarted = File(
        'docs/src/content/docs/docs/getting-started.mdx',
      ).readAsStringSync();
      expect(
        _firstCapturedInt(
          gettingStarted,
          RegExp(r'collection of (\d+) custom lint rules'),
        ),
        totalRules,
        reason: 'The Getting Started rule total is stale.',
      );
      for (final entry in expected.entries.where(
        (entry) => entry.key != 'none',
      )) {
        expect(
          _firstCapturedInt(gettingStarted, RegExp('`${entry.key}` \\((\\d+)')),
          entry.value,
          reason: 'The Getting Started ${entry.key} preset count is stale.',
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
      // Each row links to its anchor in the generated rules catalog, so the
      // row set and the directory set must match — a new category with no row
      // would otherwise only show up as a wrong total.
      final rows = <String, int>{
        for (final match in RegExp(
          r'\| \[[^\]]+\]\(https://nikoro\.github\.io/many_lints/docs/rules/'
          r'#([a-z-]+)\) \| *(\d+) \|',
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

    test('example README lists every active rule exactly once', () {
      final exampleReadme = File('example/README.md').readAsStringSync();
      final listed = RegExp(
        r'^\| `([a-z0-9_]+)` \|',
        multiLine: true,
      ).allMatches(exampleReadme).map((match) => match.group(1)!).toList();
      final registered = {
        ...registry.warningRules.keys,
        ...registry.lintRules.keys,
      }..removeAll(removedRules);

      expect(
        listed.toSet(),
        registered,
        reason: 'The example README rule catalog is incomplete or stale.',
      );
      expect(
        listed,
        hasLength(registered.length),
        reason: 'The example README rule catalog contains duplicate rows.',
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

  test('every rule page has exactly one valid introduction version badge', () {
    final packageMatch = RegExp(
      r'^version:\s*(\d+)\.(\d+)\.(\d+)',
      multiLine: true,
    ).firstMatch(File('pubspec.yaml').readAsStringSync())!;
    final packageVersion =
        int.parse(packageMatch.group(1)!) * 1000000 +
        int.parse(packageMatch.group(2)!) * 1000 +
        int.parse(packageMatch.group(3)!);
    final badgePattern = RegExp(
      r'<span class="rule-badge rule-badge--version">'
      r'(Unreleased|v(\d+)\.(\d+)\.(\d+))</span>',
    );

    for (final file
        in Directory('docs/src/content/docs/docs/rules')
            .listSync(recursive: true)
            .whereType<File>()
            .where(
              (file) => file.path.endsWith('.md') || file.path.endsWith('.mdx'),
            )) {
      final badges = badgePattern.allMatches(file.readAsStringSync()).toList();
      expect(
        badges,
        hasLength(1),
        reason:
            '${file.path} must have exactly one introduction version badge.',
      );

      final badge = badges.single;
      if (badge.group(2) case final major?) {
        final introducedVersion =
            int.parse(major) * 1000000 +
            int.parse(badge.group(3)!) * 1000 +
            int.parse(badge.group(4)!);
        expect(
          introducedVersion,
          lessThanOrEqualTo(packageVersion),
          reason:
              '${file.path} claims an introduction version newer than the '
              'package version.',
        );
      }
    }
  });

  test('primary configuration docs show both YAML locations in order', () {
    final tabGroupPattern = RegExp(
      r'<Tabs syncKey="many-lints-config-file">(.*?)</Tabs>',
      dotAll: true,
    );
    const analysisOptionsTab = '<TabItem label="analysis_options.yaml">';
    const standaloneTab = '<TabItem label="many_lints.yaml">';

    for (final path in [
      'docs/src/content/docs/docs/getting-started.mdx',
      'docs/src/content/docs/docs/configuration.mdx',
    ]) {
      final content = File(path).readAsStringSync();
      final groups = tabGroupPattern.allMatches(content).toList();

      expect(groups, isNotEmpty, reason: '$path must use configuration tabs.');
      for (final group in groups) {
        final tabs = group.group(1)!;
        expect(
          tabs,
          contains(analysisOptionsTab),
          reason: '$path must show analysis_options.yaml in every tab group.',
        );
        expect(
          tabs,
          contains(standaloneTab),
          reason: '$path must show many_lints.yaml in every tab group.',
        );
        expect(
          tabs.indexOf(analysisOptionsTab),
          lessThan(tabs.indexOf(standaloneTab)),
          reason:
              'analysis_options.yaml must be the first/default tab in $path.',
        );
        expect(tabs, contains('# analysis_options.yaml'));
        expect(tabs, contains('# many_lints.yaml'));
      }
    }

    final readme = File('README.md').readAsStringSync();
    final primaryExample = readme.indexOf(
      '# analysis_options.yaml (recommended)',
    );
    final standaloneExample = readme.indexOf(
      '# many_lints.yaml — alternative standalone file',
    );
    expect(primaryExample, isNonNegative);
    expect(standaloneExample, greaterThan(primaryExample));
  });

  test('every rule page links to related rules that exist', () {
    const pageSuffixes = ['.md', '.mdx'];
    final pages = Directory('docs/src/content/docs/docs/rules')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => _matchingSuffix(file.path, pageSuffixes) != null);
    final knownUrls = <String>{
      for (final file in pages)
        '/many_lints/docs/rules/'
            '${file.path.split(Platform.pathSeparator).reversed.elementAt(1)}/'
            '${_baseName(file.path, suffix: _matchingSuffix(file.path, pageSuffixes)!)}'
            '/',
    };

    for (final file in pages) {
      final suffix = _matchingSuffix(file.path, pageSuffixes)!;
      final name = _baseName(file.path, suffix: suffix, normalizeHyphens: true);
      final content = file.readAsStringSync();
      final headings = RegExp(
        r'^## Related rules$',
        multiLine: true,
      ).allMatches(content);
      final links = RegExp(
        r'^- \[`([a-z0-9_]+)`\]\((/many_lints/docs/rules/[^)]+/)\)',
        multiLine: true,
      ).allMatches(content).toList();

      expect(
        headings.length,
        1,
        reason: '${file.path} needs exactly one Related rules section.',
      );
      expect(
        links.length,
        inInclusiveRange(2, 4),
        reason: '${file.path} needs two to four related-rule links.',
      );
      expect(
        links.map((match) => match.group(1)),
        isNot(contains(name)),
        reason: '${file.path} links to itself.',
      );
      expect(
        links.map((match) => match.group(2)),
        everyElement(isIn(knownUrls)),
        reason: '${file.path} links to a missing rule page.',
      );
    }
  });

  test('preset guide lists the exact rules added by every tier', () {
    plugin.register(registry);
    final registered = {
      ...registry.warningRules.keys,
      ...registry.lintRules.keys,
    }..removeAll(removedRules);
    final content = File(
      'docs/src/content/docs/docs/presets.md',
    ).readAsStringSync();

    final expected = <String, Set<String>>{
      'core': coreRules,
      'recommended': recommendedRules.difference(coreRules),
      'opinionated': opinionatedRules.difference(recommendedRules),
      'pedantic': pedanticRules.difference(opinionatedRules),
    };
    for (final entry in expected.entries) {
      expect(
        _presetGuideRules(content, entry.key),
        entry.value,
        reason: 'The preset guide has a stale ${entry.key} rule list.',
      );
    }
    expect(
      _presetGuideRules(content, 'outside every preset'),
      registered.difference(pedanticRules),
      reason: 'The preset guide has a stale outside-presets rule list.',
    );
  });

  test('rule documentation metadata and options stay in sync', () {
    plugin.register(registry);

    final registered = {
      ...registry.warningRules.keys,
      ...registry.lintRules.keys,
    }..removeAll(removedRules);
    final optionPages = <String, Set<String>>{};
    final directOptionsByRule = <String, Set<String>>{};
    const pageSuffixes = ['.md', '.mdx'];

    for (final file in Directory(
      'docs/src/content/docs/docs/rules',
    ).listSync(recursive: true).whereType<File>()) {
      final suffix = _matchingSuffix(file.path, pageSuffixes);
      if (suffix == null) continue;

      final name = _baseName(file.path, suffix: suffix, normalizeHyphens: true);
      final content = file.readAsStringSync();
      final title = RegExp(
        r'^title: ([a-z0-9_]+)$',
        multiLine: true,
      ).firstMatch(content)?.group(1);
      final sidebarLabel = RegExp(
        r'^  label: ([a-z0-9_]+)$',
        multiLine: true,
      ).firstMatch(content)?.group(1);

      expect(title, name, reason: '${file.path} has a stale title.');
      expect(
        sidebarLabel,
        name,
        reason: '${file.path} has a stale sidebar label.',
      );

      final expectedPreset = coreRules.contains(name)
          ? 'core'
          : recommendedRules.contains(name)
          ? 'recommended'
          : opinionatedRules.contains(name)
          ? 'opinionated'
          : pedanticRules.contains(name)
          ? 'pedantic'
          : 'none';
      final presetClaims = <String>{
        for (final match in RegExp(
          r'(?:in|part of) the \*\*`(core|recommended|opinionated|pedantic)`\*\* preset',
        ).allMatches(content))
          match.group(1)!,
        if (RegExp(r'in \*\*no preset\*\*').hasMatch(content)) 'none',
      };
      expect(
        presetClaims,
        everyElement(expectedPreset),
        reason: '$name documents a preset that does not enable it.',
      );

      final documentedOptions = {
        for (final match in RegExp(
          r'^\| `([a-z0-9_]+)` \|',
          multiLine: true,
        ).allMatches(content))
          match.group(1)!,
      };
      final configurable = content.contains('rule-badge--config');
      expect(
        configurable,
        documentedOptions.isNotEmpty,
        reason:
            '$name must have both a Configurable badge and a non-empty '
            'options table, or neither.',
      );

      expect(
        content,
        isNot(
          matches(
            RegExp(
              r'^\s*(?:[a-z0-9_]+: —|—: —|[a-z0-9_]+: built-in set)\s*$',
              multiLine: true,
            ),
          ),
        ),
        reason: '$name contains a non-runnable YAML placeholder.',
      );

      if (documentedOptions.isNotEmpty) {
        optionPages[name] = documentedOptions;
      }

      final source = File('lib/src/rules/$name.dart').readAsStringSync();
      final sourceOptions = _directOptionKeys(source);
      directOptionsByRule[name] = sourceOptions;
      expect(
        documentedOptions,
        containsAll(sourceOptions),
        reason:
            '$name does not document every option read directly by its '
            'implementation. Missing: '
            '${sourceOptions.difference(documentedOptions)}',
      );
    }

    expect(
      registered,
      containsAll(optionPages.keys),
      reason: 'Only registered rules may have an options page.',
    );

    final configuration = File(
      'docs/src/content/docs/docs/configuration.mdx',
    ).readAsStringSync();
    final catalog = <String, Set<String>>{
      for (final match in RegExp(
        r'^\| \[`([a-z0-9_]+)`\]\([^)]*\) \| (.+) \|$',
        multiLine: true,
      ).allMatches(configuration))
        match.group(1)!: {
          for (final option in RegExp(
            r'`([a-z0-9_]+)`',
          ).allMatches(match.group(2)!))
            option.group(1)!,
        },
    };

    expect(
      catalog.keys,
      unorderedEquals(optionPages.keys),
      reason:
          'The central configurable-rule catalog must list every and only '
          'configurable rule page.',
    );
    for (final entry in catalog.entries) {
      expect(
        optionPages[entry.key],
        containsAll(entry.value),
        reason:
            'The central catalog lists an option absent from the '
            '${entry.key} page.',
      );
      expect(
        entry.value,
        containsAll(directOptionsByRule[entry.key]!),
        reason:
            'The central catalog omits an option read directly by '
            '${entry.key}.',
      );
    }
    expect(
      _firstCapturedInt(
        configuration,
        RegExp(r'\*\*(\d+) rules\*\* accept options'),
      ),
      optionPages.length,
      reason: 'The configurable-rule count is stale.',
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
    expect(totalFixes, equals(103));
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
    r'^\| `(none|core|recommended|opinionated|pedantic)` \| *(\d+) \|',
    multiLine: true,
  ).allMatches(content))
    match.group(1)!: int.parse(match.group(2)!),
};

int? _firstCapturedInt(String content, RegExp pattern) {
  final value = pattern.firstMatch(content)?.group(1);
  return value == null ? null : int.parse(value);
}

Set<String> _presetGuideRules(String content, String tier) {
  final heading = tier == 'outside every preset'
      ? RegExp(r'^## Rules outside every preset \(\d+\)$', multiLine: true)
      : RegExp(
          '^### Rules added by `${RegExp.escape(tier)}` \\(\\d+\\)\$',
          multiLine: true,
        );
  final start = heading.firstMatch(content);
  if (start == null) return const {};
  final nextSections = RegExp(
    r'^## ',
    multiLine: true,
  ).allMatches(content, start.end);
  final nextSection = nextSections.isEmpty ? null : nextSections.first;
  final section = content.substring(start.end, nextSection?.start);
  return {
    for (final match in RegExp(
      r'\[`([a-z0-9_]+)`\]\(/many_lints/docs/rules/',
    ).allMatches(section))
      match.group(1)!,
  };
}

/// Option keys read directly by a rule.
///
/// Shared option readers are covered by the page/catalog comparison; this
/// catches the common failure mode where a rule starts reading a new literal
/// key but its page is not updated. Name/number set helpers also expose an
/// automatically generated `additional_` key.
Set<String> _directOptionKeys(String source) {
  final keys = <String>{};
  final accessor = RegExp(
    r'''\.(?:boolOption|intOption|stringOption|stringListOption|patternOption|entriesOption)\(\s*['"]([^'"]+)['"]''',
    multiLine: true,
  );
  final rawLookup = RegExp(
    r'''\.options\[['"]([^'"]+)['"]\]''',
    multiLine: true,
  );
  final additiveSet = RegExp(
    r'''\.(?:nameSetOption|numberSetOption)\(\s*['"]([^'"]+)['"]''',
    multiLine: true,
  );

  for (final pattern in [accessor, rawLookup]) {
    keys.addAll(pattern.allMatches(source).map((match) => match.group(1)!));
  }
  for (final match in additiveSet.allMatches(source)) {
    final key = match.group(1)!;
    keys
      ..add(key)
      ..add('additional_$key');
  }
  return keys;
}

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
