// ignore_for_file: implementation_imports
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/util/glob.dart';
import 'package:yaml/yaml.dart';

import 'presets.dart';

class RuleConfig {
  final List<String> exclude;

  final List<String> include;

  final String? message;

  final bool? enabled;

  final Map<String, Object?> options;

  const RuleConfig({
    this.exclude = const [],
    this.include = const [],
    this.message,
    this.enabled,
    this.options = const {},
  });

  static const empty = RuleConfig();

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

  bool get isConfigured =>
      exclude.isNotEmpty ||
      include.isNotEmpty ||
      message != null ||
      options.isNotEmpty;

  bool boolOption(String key, {required bool defaultValue}) {
    final value = options[key];
    return value is bool ? value : defaultValue;
  }

  int intOption(String key, {required int defaultValue}) {
    final value = options[key];
    return value is int ? value : defaultValue;
  }

  String stringOption(String key, {required String defaultValue}) {
    final value = options[key];
    if (value is! String || value.trim().isEmpty) return defaultValue;

    return value.trim();
  }

  Set<double> numberSetOption(String key, {required Set<double> defaultValue}) {
    final replacement = options[key];
    final base = replacement is List
        ? replacement.whereType<num>().map((n) => n.toDouble()).toSet()
        : defaultValue;

    final additional = options['additional_$key'];
    if (additional is! List) return base;

    return {...base, ...additional.whereType<num>().map((n) => n.toDouble())};
  }

  List<String> stringListOption(
    String key, {
    List<String> defaultValue = const [],
  }) {
    final value = options[key];
    if (value is! List) return defaultValue;
    return value.whereType<String>().toList(growable: false);
  }

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

  RegExp? patternOption(String key, {RegExp? defaultValue}) {
    final value = options[key];
    if (value is! String || value.isEmpty) return defaultValue;

    try {
      return RegExp(value);
    } on FormatException {
      return defaultValue;
    }
  }

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
        // Edge case: an empty message would add a stray separator to every diagnostic
        if (raw is String && raw.trim().isNotEmpty) message = raw.trim();
        continue;
      }

      if (name == 'enabled') {
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
  bool matchesWholeValue(String value) {
    final match = firstMatch(value);
    return match != null && match.start == 0 && match.end == value.length;
  }
}

class ManyLintsConfig {
  final Map<String, RuleConfig> _rules;

  final Preset preset;

  const ManyLintsConfig(this._rules, {this.preset = Preset.fallback});

  static const empty = ManyLintsConfig({});

  RuleConfig forRule(String ruleName) => (_rules[ruleName] ?? RuleConfig.empty)
      .withOptionDefaults(preset.optionsFor(ruleName));

  bool isRuleEnabled(String ruleName) {
    final config = forRule(ruleName);
    final explicit = config.enabled;
    if (explicit != null) return explicit;

    if (preset.enables(ruleName)) return true;

    return config.isConfigured;
  }

  factory ManyLintsConfig.parse(String content) =>
      _parse(content, sectionKey: null);

  factory ManyLintsConfig.parseOptionsFile(String content) =>
      _parse(content, sectionKey: ConfigLoader.optionsSectionKey);

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

    // Edge case: plugins cannot report on YAML files, so a mistyped preset falls back quietly
    final presetValue = root.nodes['preset']?.value;
    final preset = presetValue is String
        ? Preset.parse(presetValue) ?? Preset.fallback
        : Preset.fallback;

    final parsed = <String, RuleConfig>{};
    final rules = root.nodes['rules'];
    if (rules is YamlMap) {
      for (final entry in rules.nodes.entries) {
        final key = entry.key;
        if (key is! YamlScalar || key.value is! String) continue;
        final name = key.value as String;
        final value = entry.value;

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

class ConfigLoader {
  ConfigLoader._();

  static const fileName = 'many_lints.yaml';

  static const optionsSectionKey = 'many_lints';

  static const _optionsFileName = 'analysis_options.yaml';

  static final Map<String, _CacheEntry> _cache = {};

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

class ResolvedRuleConfig {
  final RuleConfig config;
  final bool isExcluded;

  const ResolvedRuleConfig(this.config, {required this.isExcluded});

  static const _notExcluded = ResolvedRuleConfig(
    RuleConfig.empty,
    isExcluded: false,
  );

  factory ResolvedRuleConfig.of(RuleContext context, String ruleName) {
    final root = context.package?.root;
    if (root == null) return _notExcluded;

    return ResolvedRuleConfig.forPath(
      packageRoot: root,
      path: context.currentUnit?.file.path ?? context.definingUnit.file.path,
      ruleName: ruleName,
    );
  }

  factory ResolvedRuleConfig.forPath({
    required Folder packageRoot,
    required String path,
    required String ruleName,
  }) {
    final packageConfig = ConfigLoader.loadFor(packageRoot);
    final config = packageConfig.forRule(ruleName);

    if (!packageConfig.isRuleEnabled(ruleName)) {
      return ResolvedRuleConfig(config, isExcluded: true);
    }

    if (config.exclude.isEmpty && config.include.isEmpty) {
      return ResolvedRuleConfig(config, isExcluded: false);
    }

    // Edge case: files outside the package root keep reporting, since silent drops go unnoticed
    final relative = packageRoot.relativeIfContains(path);
    if (relative == null) {
      return ResolvedRuleConfig(config, isExcluded: false);
    }

    final posixRelativePath = relative.replaceAll(r'\', '/');

    for (final pattern in config.exclude) {
      if (Glob('/', pattern).matches(posixRelativePath)) {
        return ResolvedRuleConfig(config, isExcluded: true);
      }
    }

    if (config.include.isNotEmpty) {
      final included = config.include.any(
        (pattern) => Glob('/', pattern).matches(posixRelativePath),
      );
      if (!included) return ResolvedRuleConfig(config, isExcluded: true);
    }

    return ResolvedRuleConfig(config, isExcluded: false);
  }
}
