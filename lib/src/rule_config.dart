// ignore_for_file: implementation_imports
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/util/glob.dart';
import 'package:yaml/yaml.dart';

import 'presets.dart';

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

  /// Glob patterns, relative to the package root, that this rule is limited
  /// to. An empty list means "everywhere", which is the default.
  ///
  /// [exclude] wins over this: a file matching both is skipped. Narrowing is
  /// always safe, so the two compose without the user having to reason about
  /// ordering.
  final List<String> include;

  /// A project-specific sentence appended to every diagnostic this rule
  /// reports, or `null` to leave the message as written.
  final String? message;

  /// Whether this rule was explicitly switched on or off with `enabled:`,
  /// or `null` when the selected preset decides.
  ///
  /// This is what lets a project keep a preset and still tune it, in either
  /// direction, without restating the preset's contents.
  final bool? enabled;

  /// Free-form options for the rule, as written in YAML.
  final Map<String, Object?> options;

  const RuleConfig({
    this.exclude = const [],
    this.include = const [],
    this.message,
    this.enabled,
    this.options = const {},
  });

  static const empty = RuleConfig();

  /// Returns this configuration with missing [defaults] filled in.
  ///
  /// Explicit project options win, so a preset can provide a complete policy
  /// while remaining fully adjustable through the normal per-rule block.
  RuleConfig withOptionDefaults(Map<String, Object?> defaults) {
    if (defaults.isEmpty) return this;

    return RuleConfig(
      exclude: exclude,
      include: include,
      message: message,
      enabled: enabled,
      options: {...defaults, ...options},
    );
  }

  /// Whether the project wrote anything at all for this rule.
  ///
  /// Used to treat a configuration block as opting the rule in, so that
  /// `exclude:`, `include:`, `message:` or an option does not silently do
  /// nothing on a rule no preset covers.
  bool get isConfigured =>
      exclude.isNotEmpty ||
      include.isNotEmpty ||
      message != null ||
      options.isNotEmpty;

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

  /// Reads option [key] as a string, returning [defaultValue] when absent,
  /// when the YAML value is not a string, or when it is blank.
  ///
  /// A blank value falls back rather than being honoured: an empty suffix or
  /// prefix would match every name, silently disabling the rule it configures.
  String stringOption(String key, {required String defaultValue}) {
    final value = options[key];
    if (value is! String || value.trim().isEmpty) return defaultValue;

    return value.trim();
  }

  /// Reads option [key] as a set of numbers, following the replace/append pair
  /// of [nameSetOption]: `<key>` replaces the default set outright, and
  /// `additional_<key>` extends whichever set won.
  ///
  /// Ints and doubles are both normalised to `double`, so a user writing `180`
  /// where the code sees `180.0` still matches — YAML's distinction between
  /// the two is not one a reader of a config file expects to matter.
  Set<double> numberSetOption(String key, {required Set<double> defaultValue}) {
    final replacement = options[key];
    final base = replacement is List
        ? replacement.whereType<num>().map((n) => n.toDouble()).toSet()
        : defaultValue;

    final additional = options['additional_$key'];
    if (additional is! List) return base;

    return {...base, ...additional.whereType<num>().map((n) => n.toDouble())};
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

  /// Reads option [key] as a list of maps, for options whose entries carry
  /// several fields (`- type: Bloc` / `package: bloc` / `suffix: Bloc`).
  ///
  /// Returns `[]` when the key is absent or is not a list. Non-map items are
  /// dropped, and keys that are not strings are ignored, so a malformed entry
  /// costs the user that entry rather than crashing analysis — config problems
  /// cannot be reported as diagnostics, so they must degrade quietly.
  ///
  /// Nested structure survives parsing because [_fromYaml] stores the raw
  /// `value.value`, which keeps `YamlMap`/`YamlList` (both implement
  /// `Map`/`List`).
  List<Map<String, Object?>> entriesOption(String key) {
    final value = options[key];
    if (value is! List) return const [];

    final entries = <Map<String, Object?>>[];
    for (final item in value) {
      if (item is! Map) continue;

      final entry = <String, Object?>{};
      for (final MapEntry(:key, :value) in item.entries) {
        if (key is String) entry[key] = value;
      }
      if (entry.isNotEmpty) entries.add(entry);
    }

    return entries;
  }

  /// Reads option [key] as a regular expression, returning [defaultValue]
  /// when absent, not a string, or not valid regex syntax.
  ///
  /// An invalid pattern falls back rather than throwing: config problems
  /// cannot be surfaced as diagnostics, so they must degrade quietly.
  ///
  /// The returned pattern is meant to be applied with [matchesWholeValue],
  /// which anchors by inspecting the match span. Anchoring by wrapping the
  /// source in `^(?:...)$` would be equivalent, but the naive `'^$p\$'`
  /// spelling silently rebinds a top-level alternation — `foo|bar` becomes
  /// `^foo|bar$`, which matches `xbar`.
  RegExp? patternOption(String key, {RegExp? defaultValue}) {
    final value = options[key];
    if (value is! String || value.isEmpty) return defaultValue;

    try {
      return RegExp(value);
    } on FormatException {
      return defaultValue;
    }
  }

  /// Resolves a built-in list of names against two options: [key], which
  /// *replaces* [defaultValue] outright, and `additional_<key>`, which
  /// *appends* to whichever list won.
  ///
  /// Both may be combined — `key` chooses the base list and
  /// `additional_<key>` extends it — so a project can narrow the built-in set
  /// and add its own names in one place.
  ///
  /// The two-option split is deliberate: with a single option there is no way
  /// to say "the defaults plus one more" without restating every default, and
  /// restated defaults silently rot when this package adds a name in a later
  /// version.
  Set<String> nameSetOption(String key, {required Set<String> defaultValue}) {
    final replacement = options[key];
    final base = replacement is List
        ? replacement.whereType<String>().toSet()
        : defaultValue;

    final additional = stringListOption('additional_$key');
    if (additional.isEmpty) return base;

    return {...base, ...additional};
  }

  factory RuleConfig._fromYaml(YamlMap map) {
    final exclude = <String>[];
    final include = <String>[];
    String? message;
    bool? enabled;
    final options = <String, Object?>{};

    for (final entry in map.nodes.entries) {
      final key = entry.key;
      if (key is! YamlScalar || key.value is! String) continue;
      final name = key.value as String;
      final value = entry.value;

      if (name == 'exclude' || name == 'include') {
        final target = name == 'exclude' ? exclude : include;
        // Accept a bare scalar where a list is expected, matching how the
        // banned-* entries treat `deny:`. `include: lib/**` is the spelling
        // users reach for first.
        final raw = value.value;
        if (raw is String) {
          target.add(raw);
        } else if (value is YamlList) {
          for (final item in value) {
            if (item is String) target.add(item);
          }
        }
        continue;
      }

      if (name == 'message') {
        final raw = value.value;
        // An empty message would append a stray separator to every
        // diagnostic, so treat it as absent.
        if (raw is String && raw.trim().isNotEmpty) message = raw.trim();
        continue;
      }

      if (name == 'enabled') {
        // A non-bool leaves `enabled` null, so the preset keeps deciding.
        // Falling back rather than guessing matches how every other malformed
        // option degrades: config problems cannot be reported as diagnostics.
        final raw = value.value;
        if (raw is bool) enabled = raw;
        continue;
      }

      options[name] = value.value;
    }

    return RuleConfig(
      exclude: exclude,
      include: include,
      message: message,
      enabled: enabled,
      options: options,
    );
  }
}

extension RegExpWholeValue on RegExp {
  /// Whether this pattern matches [value] in its entirety.
  ///
  /// `firstMatch` is used rather than wrapping the source in `^(?:...)$`,
  /// because a user pattern may contain a top-level alternation that anchoring
  /// by concatenation would rebind incorrectly.
  bool matchesWholeValue(String value) {
    final match = firstMatch(value);
    return match != null && match.start == 0 && match.end == value.length;
  }
}

/// Per-rule configuration for one package.
class ManyLintsConfig {
  final Map<String, RuleConfig> _rules;

  /// The rule set this package selected with `preset:`.
  final Preset preset;

  const ManyLintsConfig(this._rules, {this.preset = Preset.fallback});

  static const empty = ManyLintsConfig({});

  RuleConfig forRule(String ruleName) => (_rules[ruleName] ?? RuleConfig.empty)
      .withOptionDefaults(preset.optionsFor(ruleName));

  /// Whether [ruleName] runs in this package.
  ///
  /// Resolved in three steps:
  ///
  /// 1. An explicit `enabled:` wins in both directions, so a project can add a
  ///    rule its preset omits or drop one the preset includes.
  /// 2. Otherwise the selected preset decides.
  /// 3. A rule the preset does not cover still runs if the project gave it a
  ///    configuration block of its own.
  ///
  /// Step 3 exists because the alternative reads as a bug. Writing an
  /// `exclude:` or an option for a rule is a clear statement that the rule is
  /// wanted — silently ignoring that block until an `enabled: true` is added
  /// beside it would make careful configuration look broken.
  bool isRuleEnabled(String ruleName) {
    final config = forRule(ruleName);
    final explicit = config.enabled;
    if (explicit != null) return explicit;

    if (preset.enables(ruleName)) return true;

    return config.isConfigured;
  }

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
  /// `preset:` and `rules:`; `null` reads them straight off the document root.
  /// Beyond that the two formats are identical, so a rule behaves the same
  /// however its configuration was written.
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

    // An unrecognized or wrongly-typed preset name falls back to the default
    // rather than throwing, for the same reason a bad rule option does: a
    // plugin cannot report a diagnostic against a YAML file, so a typo must
    // degrade quietly instead of taking down analysis.
    final presetValue = root.nodes['preset']?.value;
    final preset = presetValue is String
        ? Preset.parse(presetValue) ?? Preset.fallback
        : Preset.fallback;

    final parsed = <String, RuleConfig>{};
    final rules = root.nodes['rules'];
    // A preset alone is a complete configuration, so a missing or malformed
    // `rules:` block is not a reason to discard the preset.
    if (rules is YamlMap) {
      for (final entry in rules.nodes.entries) {
        final key = entry.key;
        if (key is! YamlScalar || key.value is! String) continue;
        final name = key.value as String;
        final value = entry.value;

        // `rule: true` / `rule: false` is the terse spelling of
        // `rule: {enabled: <bool>}`, so toggling one rule on top of a preset
        // does not require a nested block.
        if (value is YamlScalar && value.value is bool) {
          parsed[name] = RuleConfig(enabled: value.value as bool);
          continue;
        }

        if (value is! YamlMap) continue;
        parsed[name] = RuleConfig._fromYaml(value);
      }
    }

    return ManyLintsConfig(parsed, preset: preset);
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
///
/// "Excluded" covers both a rule the selected preset never switched on and a
/// file the rule's own `exclude`/`include` globs rule out. Both end in the same
/// place — the rule's diagnostics are discarded — so they share one flag.
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
    final packageConfig = ConfigLoader.loadFor(packageRoot);
    final config = packageConfig.forRule(ruleName);

    // Enablement is checked before the globs: a rule the project never turned
    // on is silent everywhere, so there is no path left to match against.
    if (!packageConfig.isRuleEnabled(ruleName)) {
      return ResolvedRuleConfig(config, isExcluded: true);
    }

    if (config.exclude.isEmpty && config.include.isEmpty) {
      return ResolvedRuleConfig(config, isExcluded: false);
    }

    // A file outside the package root has no path for a glob to match, so
    // neither list can apply and the rule reports as if unconfigured. That
    // keeps `include` consistent with `exclude`, and errs toward reporting:
    // silently dropping diagnostics for a path we cannot classify would be
    // the harder failure to notice.
    final relative = packageRoot.relativeIfContains(path);
    if (relative == null) {
      return ResolvedRuleConfig(config, isExcluded: false);
    }

    // Analyzer's own exclude handling matches globs against the path relative
    // to the options file's folder, with '/' as the separator, so normalize
    // Windows separators the same way before matching.
    final normalized = relative.replaceAll(r'\', '/');

    // `exclude` is checked first so it wins over `include` for a file matching
    // both. Both directions narrow, so the combination can only ever be
    // quieter than either alone — there is no ordering the user has to learn.
    for (final pattern in config.exclude) {
      if (Glob('/', pattern).matches(normalized)) {
        return ResolvedRuleConfig(config, isExcluded: true);
      }
    }

    if (config.include.isNotEmpty) {
      final included = config.include.any(
        (pattern) => Glob('/', pattern).matches(normalized),
      );
      if (!included) return ResolvedRuleConfig(config, isExcluded: true);
    }

    return ResolvedRuleConfig(config, isExcluded: false);
  }
}
