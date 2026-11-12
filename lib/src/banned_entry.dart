// ignore_for_file: implementation_imports
import 'package:analyzer/src/util/glob.dart';

import 'rule_config.dart';

class BannedEntry {
  final Set<String> deny;

  final List<RegExp> denyPatterns;

  final List<String> paths;

  final List<String> exceptPaths;

  final String? message;

  BannedEntry({
    required this.deny,
    required this.denyPatterns,
    required this.paths,
    required this.exceptPaths,
    required this.message,
  }) : _pathGlobs = _compile(paths),
       _exceptGlobs = _compile(exceptPaths);

  final List<Glob> _pathGlobs;
  final List<Glob> _exceptGlobs;

  bool get isEmpty => deny.isEmpty && denyPatterns.isEmpty;

  bool matches(String value, {bool patterns = true}) {
    if (deny.contains(value)) return true;
    if (!patterns) return false;

    for (final pattern in denyPatterns) {
      if (pattern.matchesWholeValue(value)) return true;
    }

    return false;
  }

  bool appliesTo(String? relativePath) {
    if (relativePath == null) return paths.isEmpty;
    if (_exceptGlobs.any((glob) => glob.matches(relativePath))) return false;

    return paths.isEmpty ||
        _pathGlobs.any((glob) => glob.matches(relativePath));
  }

  static List<Glob> _compile(List<String> patterns) => [
    for (final pattern in patterns) Glob('/', pattern),
  ];
}

List<BannedEntry> readBannedEntries(RuleConfig config) {
  final entries = <BannedEntry>[];

  for (final raw in config.entriesOption('banned')) {
    final entry = BannedEntry(
      deny: _stringList(raw['deny']).toSet(),
      denyPatterns: _regExpList(raw['deny_pattern']),
      paths: _stringList(raw['in']),
      exceptPaths: _stringList(raw['except']),
      message: _nonEmptyString(raw['message']),
    );

    if (entry.isEmpty) continue;
    entries.add(entry);
  }

  return entries;
}

String? _nonEmptyString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

List<String> _stringList(Object? value) {
  if (value is String) return value.isEmpty ? const [] : [value];
  if (value is! List) return const [];

  return [
    for (final item in value)
      if (item is String && item.isNotEmpty) item,
  ];
}

List<RegExp> _regExpList(Object? value) {
  final patterns = <RegExp>[];

  for (final source in _stringList(value)) {
    try {
      patterns.add(RegExp(source));
    } on FormatException {
      continue;
    }
  }

  return patterns;
}

BannedEntry? findBannedEntry({
  required List<BannedEntry> entries,
  required String value,
  required String? relativePath,
  bool patterns = true,
}) {
  for (final entry in entries) {
    if (!entry.matches(value, patterns: patterns)) continue;
    if (!entry.appliesTo(relativePath)) continue;

    return entry;
  }

  return null;
}

String messageSuffix(BannedEntry entry) {
  final message = entry.message;
  return message == null ? '' : ' $message';
}
