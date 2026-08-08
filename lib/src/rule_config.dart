// ignore_for_file: implementation_imports
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/util/glob.dart';
import 'package:yaml/yaml.dart';

/// Per-rule configuration read from a `many_lints.yaml` file at the package
/// root.
///
/// The analyzer's own options system cannot carry this. Under
/// `plugins: many_lints:` only `{diagnostics, git, path, version, hosted}` are
/// legal keys — anything else is reported as `unsupported_option` — and the
/// `diagnostics:` values are restricted to enable/disable/severity scalars.
/// A rule instance also never receives the [AnalysisOptions] object: the
/// options are consumed by the plugin server purely to decide *which* rules run
/// and at what severity, and [RuleContext] exposes no path back to them.
///
/// So configuration lives in a sibling file that this package parses itself:
///
/// ```yaml
/// # many_lints.yaml
/// rules:
///   avoid_border_all:
///     exclude:
///       - test/**
///       - "**/*.g.dart"
///     allow_non_const: true
/// ```
class RuleConfig {
  /// Glob patterns, relative to the package root, that this rule skips.
  final List<String> exclude;

  /// Free-form options for the rule, as written in YAML.
  final Map<String, Object?> options;

  const RuleConfig({this.exclude = const [], this.options = const {}});

  static const empty = RuleConfig();

  /// Reads option [key] as a bool, returning [defaultValue] when absent or
  /// when the YAML value is not a bool.
  bool boolOption(String key, {required bool defaultValue}) {
    final value = options[key];
    return value is bool ? value : defaultValue;
  }

  /// Reads option [key] as an int, returning [defaultValue] when absent or
  /// when the YAML value is not an int.
  int intOption(String key, {required int defaultValue}) {
    final value = options[key];
    return value is int ? value : defaultValue;
  }

  /// Reads option [key] as a list of strings, returning [defaultValue] when
  /// absent or when the YAML value is not a list.
  List<String> stringListOption(
    String key, {
    List<String> defaultValue = const [],
  }) {
    final value = options[key];
    if (value is! List) return defaultValue;
    return value.whereType<String>().toList(growable: false);
  }

  factory RuleConfig._fromYaml(YamlMap map) {
    final exclude = <String>[];
    final options = <String, Object?>{};

    for (final entry in map.nodes.entries) {
      final key = entry.key;
      if (key is! YamlScalar || key.value is! String) continue;
      final name = key.value as String;
      final value = entry.value;

      if (name == 'exclude') {
        if (value is YamlList) {
          for (final item in value) {
            if (item is String) exclude.add(item);
          }
        }
        continue;
      }

      options[name] = value.value;
    }

    return RuleConfig(exclude: exclude, options: options);
  }
}

/// Per-rule configuration for one package.
class ManyLintsConfig {
  final Map<String, RuleConfig> _rules;

  const ManyLintsConfig(this._rules);

  static const empty = ManyLintsConfig({});

  RuleConfig forRule(String ruleName) => _rules[ruleName] ?? RuleConfig.empty;

  /// Parses [content] as a `many_lints.yaml` file, whose `rules:` key sits at
  /// the document root.
  ///
  /// Malformed YAML yields [empty] rather than throwing: a broken config file
  /// must not take down analysis of the whole package.
  factory ManyLintsConfig.parse(String content) =>
      _parse(content, sectionKey: null);

  /// Parses [content] as an `analysis_options.yaml` file, reading the `rules:`
  /// key nested under a top-level `many_lints:` section.
  ///
  /// Yields [empty] when that section is absent, which is the common case.
  factory ManyLintsConfig.parseOptionsFile(String content) =>
      _parse(content, sectionKey: ConfigLoader.optionsSectionKey);

  /// Shared parser for both sources.
  ///
  /// [sectionKey] names a top-level key to descend into before looking for
  /// `rules:`; `null` reads `rules:` straight off the document root. Beyond
  /// that the two formats are identical, so a rule behaves the same however
  /// its configuration was written.
  static ManyLintsConfig _parse(String content, {required String? sectionKey}) {
    final YamlNode doc;
    try {
      doc = loadYamlNode(content);
    } on YamlException {
      return empty;
    }

    if (doc is! YamlMap) return empty;

    YamlMap root = doc;
    if (sectionKey != null) {
      final section = doc.nodes[sectionKey];
      if (section is! YamlMap) return empty;
      root = section;
    }

    final rules = root.nodes['rules'];
    if (rules is! YamlMap) return empty;

    final parsed = <String, RuleConfig>{};
    for (final entry in rules.nodes.entries) {
      final key = entry.key;
      if (key is! YamlScalar || key.value is! String) continue;
      final value = entry.value;
      if (value is! YamlMap) continue;
      parsed[key.value as String] = RuleConfig._fromYaml(value);
    }

    return ManyLintsConfig(parsed);
  }
}

/// Loads and caches per-rule configuration for a package root.
///
/// Configuration is read from one of two places, in this order:
///
/// 1. `many_lints.yaml` at the package root.
/// 2. A top-level `many_lints:` section in `analysis_options.yaml`.
///
/// When both are present the dedicated file wins outright — the sections are
/// not merged, since merging `exclude` lists across two files makes "where did
/// this pattern come from" very hard to answer. The conflict is resolved
/// silently because a plugin cannot report a diagnostic against a YAML file:
/// `PluginServer` restricts analyzed paths to Dart files (see its own TODO
/// about enabling analysis of analysis-options and pubspec YAML).
///
/// A top-level `many_lints:` key is safe to add to `analysis_options.yaml`:
/// the analyzer only validates the interior of sections it knows, so an
/// unrecognized top-level key produces no `unsupported_option` warning. Note
/// that it does *not* inherit through `include:` either, for the same reason —
/// the analyzer never parses it.
///
/// Rule instances are long-lived singletons shared across every analysis
/// context, so the cache is keyed by package root path rather than stored on
/// the rule. Entries record both files' modification stamps so that editing
/// either one is picked up without restarting the analysis server.
class ConfigLoader {
  ConfigLoader._();

  /// The dedicated configuration file, which takes precedence.
  static const fileName = 'many_lints.yaml';

  /// The top-level key read from `analysis_options.yaml` as a fallback.
  static const optionsSectionKey = 'many_lints';

  static const _optionsFileName = 'analysis_options.yaml';

  static final Map<String, _CacheEntry> _cache = {};

  /// Clears the cache. Exposed for tests.
  static void clearCache() => _cache.clear();

  static ManyLintsConfig loadFor(Folder packageRoot) {
    final dedicated = packageRoot.getFile(fileName);
    final options = packageRoot.getFile(_optionsFileName);

    final dedicatedStamp = _stampOf(dedicated);
    final optionsStamp = _stampOf(options);

    final cached = _cache[packageRoot.path];
    if (cached != null &&
        cached.dedicatedStamp == dedicatedStamp &&
        cached.optionsStamp == optionsStamp) {
      return cached.config;
    }

    final config = _read(
      dedicated: dedicated,
      dedicatedStamp: dedicatedStamp,
      options: options,
      optionsStamp: optionsStamp,
    );

    _cache[packageRoot.path] = _CacheEntry(
      dedicatedStamp: dedicatedStamp,
      optionsStamp: optionsStamp,
      config: config,
    );
    return config;
  }

  static ManyLintsConfig _read({
    required File dedicated,
    required int? dedicatedStamp,
    required File options,
    required int? optionsStamp,
  }) {
    if (dedicatedStamp != null) {
      final content = _contentOf(dedicated);
      if (content != null) return ManyLintsConfig.parse(content);
    }

    if (optionsStamp != null) {
      final content = _contentOf(options);
      if (content != null) return ManyLintsConfig.parseOptionsFile(content);
    }

    return ManyLintsConfig.empty;
  }

  static int? _stampOf(File file) {
    try {
      return file.exists ? file.modificationStamp : null;
    } on FileSystemException {
      return null;
    }
  }

  static String? _contentOf(File file) {
    try {
      return file.readAsStringSync();
    } on FileSystemException {
      return null;
    }
  }
}

class _CacheEntry {
  final int? dedicatedStamp;
  final int? optionsStamp;
  final ManyLintsConfig config;

  const _CacheEntry({
    required this.dedicatedStamp,
    required this.optionsStamp,
    required this.config,
  });
}

/// Resolves the configuration for [ruleName] in the package currently being
/// analyzed, and reports whether the current file is excluded from it.
class ResolvedRuleConfig {
  final RuleConfig config;
  final bool isExcluded;

  const ResolvedRuleConfig(this.config, {required this.isExcluded});

  static const _notExcluded = ResolvedRuleConfig(
    RuleConfig.empty,
    isExcluded: false,
  );

  /// Resolves configuration for [ruleName] from [context].
  ///
  /// Must be called from inside a visitor callback: [RuleContext.currentUnit]
  /// is null while `registerNodeProcessors` runs, and only the current unit
  /// gives the path of the file actually being visited (a library's parts can
  /// live in different directories than its defining unit).
  factory ResolvedRuleConfig.of(RuleContext context, String ruleName) {
    final root = context.package?.root;
    if (root == null) return _notExcluded;

    return ResolvedRuleConfig.forPath(
      packageRoot: root,
      path: context.currentUnit?.file.path ?? context.definingUnit.file.path,
      ruleName: ruleName,
    );
  }

  /// Resolves configuration for [ruleName] against an explicit [path].
  ///
  /// Used by `ManyLintsRule`, which intercepts the diagnostic reporter and so
  /// knows the file being reported on without holding a [RuleContext].
  factory ResolvedRuleConfig.forPath({
    required Folder packageRoot,
    required String path,
    required String ruleName,
  }) {
    final config = ConfigLoader.loadFor(packageRoot).forRule(ruleName);
    if (config.exclude.isEmpty) {
      return ResolvedRuleConfig(config, isExcluded: false);
    }

    final relative = packageRoot.relativeIfContains(path);
    if (relative == null) {
      return ResolvedRuleConfig(config, isExcluded: false);
    }

    // Analyzer's own exclude handling matches globs against the path relative
    // to the options file's folder, with '/' as the separator, so normalize
    // Windows separators the same way before matching.
    final normalized = relative.replaceAll(r'\', '/');
    for (final pattern in config.exclude) {
      if (Glob('/', pattern).matches(normalized)) {
        return ResolvedRuleConfig(config, isExcluded: true);
      }
    }

    return ResolvedRuleConfig(config, isExcluded: false);
  }
}
