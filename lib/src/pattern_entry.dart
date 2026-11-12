// ignore_for_file: implementation_imports
import 'package:analyzer/src/util/glob.dart';

import 'rule_config.dart';

enum PatternNode {
  methodInvocation,

  propertyAccess;

  static PatternNode? tryParse(String value) {
    final normalized = value.toLowerCase().replaceAll(RegExp('[_-]'), '');

    for (final node in values) {
      if (node.name.toLowerCase() == normalized) return node;
    }

    return null;
  }
}

class PatternEntry {
  final RegExp find;

  final String? replace;

  final PatternNode node;

  final List<String> paths;

  final String? message;

  const PatternEntry({
    required this.find,
    required this.replace,
    required this.node,
    required this.paths,
    required this.message,
  });

  bool appliesTo(String? relativePath) {
    if (paths.isEmpty) return true;
    if (relativePath == null) return false;

    for (final pattern in paths) {
      if (Glob('/', pattern).matches(relativePath)) return true;
    }

    return false;
  }

  String? replacementFor(String source) {
    final template = replace;
    if (template == null) return null;

    final match = find.matchAsPrefix(source);
    if (match == null || match.end != source.length) return null;

    return expandTemplate(template, match);
  }
}

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

String patternMessageSuffix(PatternEntry entry) {
  final message = entry.message;
  return message == null ? '' : ' $message';
}
