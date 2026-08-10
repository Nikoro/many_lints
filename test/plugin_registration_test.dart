// ignore_for_file: implementation_imports
import 'dart:io';

import 'package:analysis_server_plugin/src/registry.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:many_lints/many_lints.dart' as many_lints;
import 'package:many_lints/many_lints.dart';
import 'package:many_lints/src/many_lints_rule.dart';
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
    expect(totalRules, equals(155));
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
    final sources = _baseNames(Directory('lib/src/rules'), suffix: '.dart')
      ..remove('AGENTS');
    final docs = _baseNames(
      Directory('docs/src/content/docs/docs/rules'),
      suffix: '.md',
      recursive: true,
      normalizeHyphens: true,
    );
    final examples = _baseNames(
      Directory('example/lib'),
      suffix: '_example.dart',
    );
    final directTests = _baseNames(Directory('test'), suffix: '_test.dart');

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

  test('documentation fix badges match registered quick fixes', () {
    plugin.register(registry);

    final registeredFixes = registry.fixKinds.values
        .expand((codes) => codes)
        .toSet();
    final documentedFixes = <String>{
      for (final file in Directory(
        'docs/src/content/docs/docs/rules',
      ).listSync(recursive: true).whereType<File>())
        if (file.path.endsWith('.md') &&
            file.readAsStringSync().contains('rule-badge--fix'))
          _baseName(file.path, suffix: '.md', normalizeHyphens: true),
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
    expect(totalFixes, equals(90));
  });

  test('assists are registered', () {
    plugin.register(registry);
    expect(registry.assistKinds.length, equals(1));
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

Set<String> _baseNames(
  Directory directory, {
  required String suffix,
  bool recursive = false,
  bool normalizeHyphens = false,
}) => {
  for (final file in directory.listSync(recursive: recursive).whereType<File>())
    if (file.path.endsWith(suffix))
      _baseName(file.path, suffix: suffix, normalizeHyphens: normalizeHyphens),
};

String _baseName(
  String path, {
  required String suffix,
  bool normalizeHyphens = false,
}) {
  final fileName = path.split(Platform.pathSeparator).last;
  final name = fileName.substring(0, fileName.length - suffix.length);
  return normalizeHyphens ? name.replaceAll('-', '_') : name;
}
