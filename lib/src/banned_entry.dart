// ignore_for_file: implementation_imports
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/util/glob.dart';

import 'rule_config.dart';

/// One configured `banned:` item: what to deny, where it applies, and why.
///
/// Shared by every rule in the `avoid_banned_*` family plus [banned_usage], so
/// a project writes one entry shape no matter which rule reads it. A generic
/// `entries:` key invites reuse across unrelated rules to mean unrelated
/// shapes; naming the key after its concept keeps that from happening here.
class BannedEntry {
  /// Values denied by exact match.
  ///
  /// Exact by default is deliberate. Were `deny:` entries regexes matched as
  /// *substrings*, banning `visibleForTesting` would also hit
  /// `notVisibleForTesting`, leaving users to anchor every pattern with
  /// `^`/`$`. Opt into patterns with [denyPatterns].
  final Set<String> deny;

  /// Values denied by regular expression, anchored to the whole value.
  ///
  /// Anchoring is applied here rather than left to the user, so a pattern
  /// cannot silently match a substring.
  final List<RegExp> denyPatterns;

  /// Globs, relative to the package root, limiting where this entry applies.
  ///
  /// Empty means everywhere. Globs (not regexes) keep path semantics identical
  /// to `exclude:`, and [Folder.relativeIfContains] normalizes separators, so
  /// the Windows-path caveat that separator-sensitive matching invites does
  /// not arise.
  final List<String> paths;

  /// A project-specific explanation appended to the diagnostic, or `null`.
  final String? message;

  const BannedEntry({
    required this.deny,
    required this.denyPatterns,
    required this.paths,
    required this.message,
  });

  /// Whether this entry has nothing to deny, in which case it is inert.
  bool get isEmpty => deny.isEmpty && denyPatterns.isEmpty;

  /// Whether [value] is denied by this entry, ignoring path scope.
  bool matches(String value) {
    if (deny.contains(value)) return true;

    for (final pattern in denyPatterns) {
      if (pattern.matchesWholeValue(value)) return true;
    }

    return false;
  }

  /// Whether this entry applies to the file at [relativePath].
  ///
  /// An entry with no `in:` applies everywhere; [relativePath] is `null` when
  /// the file lies outside the package root, which is also treated as in scope
  /// so a scoped entry never silently stops applying.
  bool appliesTo(String? relativePath) {
    if (paths.isEmpty) return true;
    if (relativePath == null) return false;

    for (final pattern in paths) {
      if (Glob('/', pattern).matches(relativePath)) return true;
    }

    return false;
  }
}

/// Reads the `banned:` list from [config].
///
/// Takes a [RuleConfig] rather than a rule so any consumer holding a resolved
/// config — including a quick fix, which has no rule instance — resolves
/// exactly the same entries.
///
/// Malformed entries are dropped rather than reported: a plugin cannot report
/// diagnostics against a YAML file at all, so bad configuration has to degrade
/// quietly instead of breaking analysis of the whole package. An invalid regex
/// costs the user that pattern and nothing else.
List<BannedEntry> readBannedEntries(RuleConfig config) {
  final entries = <BannedEntry>[];

  for (final raw in config.entriesOption('banned')) {
    final entry = BannedEntry(
      deny: _stringList(raw['deny']).toSet(),
      denyPatterns: _regExpList(raw['deny_pattern']),
      paths: _stringList(raw['in']),
      message: _nonEmptyString(raw['message']),
    );

    // An entry denying nothing would match nothing; dropping it keeps
    // `isEmpty` from having to be re-checked at every call site.
    if (entry.isEmpty) continue;
    entries.add(entry);
  }

  return entries;
}

/// Returns [value] when it is a non-empty string, else `null`.
///
/// An empty `message:` is treated as absent rather than appended as a stray
/// space — the degenerate value should not change how a diagnostic reads.
String? _nonEmptyString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

/// Normalizes a YAML value that may be a single string or a list of strings.
///
/// Accepting a bare scalar is a convenience for the common one-value case
/// (`deny: package:flutter/material.dart`); it costs nothing and removes a
/// class of "why is my config ignored" confusion.
List<String> _stringList(Object? value) {
  if (value is String) return value.isEmpty ? const [] : [value];
  if (value is! List) return const [];

  return [
    for (final item in value)
      if (item is String && item.isNotEmpty) item,
  ];
}

/// Compiles patterns, dropping any that fail to parse.
List<RegExp> _regExpList(Object? value) {
  final patterns = <RegExp>[];

  for (final source in _stringList(value)) {
    try {
      patterns.add(RegExp(source));
    } on FormatException {
      // Degrade quietly — see [readBannedEntries].
      continue;
    }
  }

  return patterns;
}

/// The first entry denying [value] in a file at [relativePath], or `null`.
BannedEntry? findBannedEntry({
  required List<BannedEntry> entries,
  required String value,
  required String? relativePath,
}) {
  for (final entry in entries) {
    if (!entry.appliesTo(relativePath)) continue;
    if (!entry.matches(value)) continue;

    return entry;
  }

  return null;
}

/// Builds the message argument carrying an entry's optional explanation.
///
/// Returns an empty string when no `message:` is configured, so the diagnostic
/// reads cleanly either way rather than trailing an empty sentence.
String messageSuffix(BannedEntry entry) {
  final message = entry.message;
  return message == null ? '' : ' $message';
}
