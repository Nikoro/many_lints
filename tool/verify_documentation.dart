import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:yaml/yaml.dart';

final _dartFence = RegExp(
  r'^```dart[^\n]*\n([\s\S]*?)^```\s*$',
  multiLine: true,
);
final _yamlFence = RegExp(
  r'^```ya?ml[^\n]*\n([\s\S]*?)^```\s*$',
  multiLine: true,
);
final _configTabs = RegExp(
  r'<Tabs\s+syncKey="many-lints-config-file">([\s\S]*?)</Tabs>',
);
final _internalLink = RegExp(r'\]\((/many_lints/docs/[^)#?]*)(?:#[^)]+)?\)');

void main() {
  final docsRoot = Directory('docs/src/content/docs/docs');
  if (!docsRoot.existsSync()) {
    stderr.writeln('Run this command from the package root.');
    exitCode = 64;
    return;
  }

  final pages =
      docsRoot
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (file) => file.path.endsWith('.md') || file.path.endsWith('.mdx'),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  final failures = <String>[];
  var dartSnippetCount = 0;
  var yamlSnippetCount = 0;
  var configPairCount = 0;

  final routes = pages.map((file) => _routeFor(file, docsRoot.path)).toSet();

  for (final page in pages) {
    final source = page.readAsStringSync();

    for (final match in _dartFence.allMatches(source)) {
      dartSnippetCount++;
      final snippet = match.group(1)!;
      if (!_parsesInDocumentedContext(snippet)) {
        failures.add(
          '${page.path}:${_lineAt(source, match.start)} contains a Dart '
          'snippet that is not syntactically valid as a library, function '
          'body, or class body.',
        );
      }
    }

    for (final match in _yamlFence.allMatches(source)) {
      yamlSnippetCount++;
      try {
        loadYaml(match.group(1)!);
      } on YamlException catch (error) {
        failures.add(
          '${page.path}:${_lineAt(source, match.start)} contains invalid YAML: '
          '${error.message}',
        );
      }
    }

    for (final tabsMatch in _configTabs.allMatches(source)) {
      final snippets = _yamlFence
          .allMatches(tabsMatch.group(1)!)
          .map((match) => match.group(1)!)
          .toList();
      if (snippets.length != 2) {
        failures.add(
          '${page.path}:${_lineAt(source, tabsMatch.start)} must contain '
          'exactly two YAML snippets in its synchronized config tabs.',
        );
        continue;
      }

      configPairCount++;
      try {
        final analysisOptions = loadYaml(snippets.first);
        final standalone = loadYaml(snippets.last);
        final embedded = analysisOptions is YamlMap
            ? _yamlMapValue(analysisOptions, 'many_lints')
            : null;
        if (jsonEncode(_canonicalYaml(embedded)) !=
            jsonEncode(_canonicalYaml(standalone))) {
          failures.add(
            '${page.path}:${_lineAt(source, tabsMatch.start)} has different '
            'configuration in the analysis_options.yaml and many_lints.yaml '
            'tabs.',
          );
        }
      } on YamlException {
        // The individual-fence check above reports the more useful location.
      }
    }

    for (final linkMatch in _internalLink.allMatches(source)) {
      final route = linkMatch.group(1)!.replaceFirst(RegExp(r'/$'), '');
      if (!routes.contains(route)) {
        failures.add(
          '${page.path}:${_lineAt(source, linkMatch.start)} links to missing '
          'documentation route $route.',
        );
      }
    }
  }

  if (failures.isNotEmpty) {
    stderr.writeln('Documentation verification failed:');
    for (final failure in failures) {
      stderr.writeln('- $failure');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Verified ${pages.length} documentation pages: $dartSnippetCount Dart '
    'snippets, $yamlSnippetCount YAML snippets, $configPairCount synchronized '
    'config pairs, and all internal documentation links.',
  );
}

bool _parsesInDocumentedContext(String snippet) {
  final candidates = <String>[
    snippet,
    'void _snippet() {\n$snippet\n}',
    'Future<void> _snippet() async {\n$snippet\n}',
    'class _Snippet {\n$snippet\n}',
    'class User {\n$snippet\n}',
    'final Object? _snippet = $snippet;',
    'final List<Object?> _snippet = <Object?>[$snippet];',
    'void _snippet($snippet) {}',
    'void _snippet() { _call($snippet); }',
    'class _Snippet { _Snippet() : $snippet; }',
    'void _snippet(Object? value) { switch (value) { $snippet } }',
  ];

  return candidates.any((candidate) {
    final result = parseString(
      content: candidate,
      featureSet: FeatureSet.latestLanguageVersion(),
      throwIfDiagnostics: false,
    );
    return result.errors.isEmpty;
  });
}

String _routeFor(File file, String docsRoot) {
  var relative = file.path.substring(docsRoot.length + 1);
  relative = relative.replaceFirst(RegExp(r'\.mdx?$'), '');
  if (relative.endsWith('/index')) {
    relative = relative.substring(0, relative.length - '/index'.length);
  }
  return '/many_lints/docs/$relative';
}

int _lineAt(String source, int offset) =>
    '\n'.allMatches(source.substring(0, offset)).length + 1;

Object? _canonicalYaml(Object? value) => switch (value) {
  final YamlMap map => Map.fromEntries(
    map.entries
        .map((entry) => MapEntry('${entry.key}', _canonicalYaml(entry.value)))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key)),
  ),
  final YamlList list => list.map(_canonicalYaml).toList(),
  final YamlScalar scalar => scalar.value,
  _ => value,
};

Object? _yamlMapValue(YamlMap map, String key) {
  for (final entry in map.entries) {
    if ('${entry.key}' == key) return entry.value;
  }
  return null;
}
