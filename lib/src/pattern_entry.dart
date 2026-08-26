// ignore_for_file: implementation_imports
import 'package:analyzer/src/util/glob.dart';

import 'rule_config.dart';

/// Which kind of AST node a pattern is matched against.
///
/// The pattern is tested against the node's **source text**, so the node kind
/// is what gives the match its boundaries. Naming the kind in configuration —
/// rather than matching raw lines — is what keeps a pattern from spanning a
/// statement it was never meant to see.
enum PatternNode {
  /// A call: `unawaited(x)`, `DateTime.now()`, `Theme.of(context)`.
  methodInvocation,

  /// A property read with no argument list: `Theme.of(context).textTheme`.
  ///
  /// Needed for replacements whose right-hand end is a property rather than a
  /// call — with [methodInvocation] alone the matched node stops at the call
  /// and the trailing `.property` cannot be rewritten with it.
  propertyAccess;

  /// The kind named by [value], or `null` when it names none.
  ///
  /// Matched case-insensitively and ignoring `_`/`-`, so `methodInvocation`,
  /// `method_invocation` and `method-invocation` all resolve. Configuration is
  /// hand-written; a spelling that is obviously intended should not silently
  /// disable an entry.
  static PatternNode? tryParse(String value) {
    final normalized = value.toLowerCase().replaceAll(RegExp('[_-]'), '');

    for (final node in values) {
      if (node.name.toLowerCase() == normalized) return node;
    }

    return null;
  }
}

/// One configured `patterns:` item: what to match, what to offer, and where.
///
/// Mirrors the shape of `BannedEntry` — `in:`-globs and an optional
/// `message:` — so a project writes one familiar entry shape whichever rule
/// reads it.
class PatternEntry {
  /// The pattern, matched against the whole source text of a node.
  ///
  /// Anchored at match time rather than by rewriting the source here, for the
  /// reason spelled out on [RuleConfig.patternOption]: the naive `'^$p\$'`
  /// spelling silently rebinds a top-level alternation.
  final RegExp find;

  /// The replacement template, or `null` when this entry only reports.
  ///
  /// A missing `replace:` is how an entry opts *out* of rewriting: nothing is
  /// offered unless the author asked for it.
  final String? replace;

  /// Which node kind [find] is tested against.
  final PatternNode node;

  /// Globs, relative to the package root, limiting where this entry applies.
  final List<String> paths;

  /// A project-specific explanation appended to the diagnostic, or `null`.
  final String? message;

  const PatternEntry({
    required this.find,
    required this.replace,
    required this.node,
    required this.paths,
    required this.message,
  });

  /// Whether this entry applies to the file at [relativePath].
  ///
  /// An entry with no `in:` applies everywhere; [relativePath] is `null` when
  /// the file lies outside the package root.
  bool appliesTo(String? relativePath) {
    if (paths.isEmpty) return true;
    if (relativePath == null) return false;

    for (final pattern in paths) {
      if (Glob('/', pattern).matches(relativePath)) return true;
    }

    return false;
  }

  /// The replacement for [source], or `null` when this entry cannot produce
  /// one.
  ///
  /// Returns `null` when the entry has no `replace:`, or when [source] is not
  /// a whole-value match — the caller reports on the same condition, so the
  /// two cannot disagree about what matched.
  String? replacementFor(String source) {
    final template = replace;
    if (template == null) return null;

    final match = find.matchAsPrefix(source);
    if (match == null || match.end != source.length) return null;

    return expandTemplate(template, match);
  }
}

/// Substitutes `$0`..`$9` in [template] with [match]'s groups.
///
/// `$$` is a literal `$`, which is the only escape: a template is a small
/// string, and one escape that reads the same as it does in a shell beats a
/// scheme nobody remembers. A group that did not participate in the match
/// expands to the empty string, and a `$` followed by anything else is left
/// alone rather than swallowed.
String expandTemplate(String template, Match match) {
  final buffer = StringBuffer();

  for (var i = 0; i < template.length; i++) {
    final char = template[i];

    if (char != r'$' || i + 1 >= template.length) {
      buffer.write(char);
      continue;
    }

    final next = template[i + 1];

    if (next == r'$') {
      buffer.write(r'$');
      i++;
      continue;
    }

    final group = int.tryParse(next);
    if (group == null || group > match.groupCount) {
      buffer.write(char);
      continue;
    }

    buffer.write(match.group(group) ?? '');
    i++;
  }

  return buffer.toString();
}

/// Reads the `patterns:` list from [config].
///
/// Malformed entries are dropped rather than reported, like every other
/// malformed option: a plugin cannot report diagnostics against a YAML file,
/// so bad configuration degrades quietly instead of breaking analysis. An
/// invalid regex costs the user that entry and nothing else.
List<PatternEntry> readPatternEntries(RuleConfig config) {
  final entries = <PatternEntry>[];

  for (final raw in config.entriesOption('patterns')) {
    final find = _tryRegExp(raw['find']);
    if (find == null) continue;

    final node = _readNode(raw['node']);
    if (node == null) continue;

    entries.add(
      PatternEntry(
        find: find,
        replace: _nonEmptyString(raw['replace']),
        node: node,
        paths: _stringList(raw['in']),
        message: _nonEmptyString(raw['message']),
      ),
    );
  }

  return entries;
}

/// The node kind named by [value], defaulting to [PatternNode.methodInvocation].
///
/// Returns `null` for a string naming no kind, which drops the entry: a typo
/// there would otherwise silently retarget the pattern at calls, where it
/// could match something the author never looked at.
PatternNode? _readNode(Object? value) {
  if (value == null) return PatternNode.methodInvocation;
  if (value is! String) return null;

  return PatternNode.tryParse(value);
}

RegExp? _tryRegExp(Object? value) {
  if (value is! String || value.isEmpty) return null;

  try {
    return RegExp(value);
  } on FormatException {
    return null;
  }
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

/// The first entry matching [source] in a file at [relativePath], or `null`.
PatternEntry? findPatternEntry({
  required List<PatternEntry> entries,
  required PatternNode node,
  required String source,
  required String? relativePath,
}) {
  for (final entry in entries) {
    if (entry.node != node) continue;
    if (!entry.appliesTo(relativePath)) continue;
    if (!entry.find.matchesWholeValue(source)) continue;

    return entry;
  }

  return null;
}

/// Builds the message argument carrying an entry's optional explanation.
String patternMessageSuffix(PatternEntry entry) {
  final message = entry.message;
  return message == null ? '' : ' $message';
}
