import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:test/test.dart';

import 'fix_harness.dart';
import 'fpdart_stub.dart';

void main() {
  late FixHarness harness;

  setUp(() async {
    harness = FixHarness();
    await harness.setUp();
  });

  tearDown(() async {
    await harness.tearDown();
  });

  final pages = _rulePages();

  test('the docs glob still finds the rule pages', () {
    expect(pages, hasLength(greaterThan(200)));
  });

  final checkable = <_Page>[];
  final skipped = <String, String>{};

  for (final page in pages) {
    final reason = _skipReason(page);
    if (reason == null) {
      checkable.add(page);
    } else {
      skipped[page.rule] = reason;
    }
  }

  test('coverage is not silently shrinking', () {
    expect(
      checkable,
      hasLength(greaterThanOrEqualTo(_minimumCheckedPages)),
      reason:
          'Only ${checkable.length} of ${pages.length} rule pages are being '
          'verified, below the floor of $_minimumCheckedPages. Skipped: '
          '${skipped.entries.map((e) => '${e.key} (${e.value})').join(', ')}',
    );
  });

  for (final page in checkable) {
    final rule = page.rule;

    test("docs Don't example reports: $rule", () async {
      final source = _wrap(page.dontSnippet!, page)!;

      final codes = await harness.diagnosticsFor(
        source,
        rule,
        packages: page.needsFlutter ? {'flutter': flutterWidgets} : const {},
        multiFilePackages: page.needsFpdart
            ? {'fpdart': fpdartStubFiles}
            : const {},
        manyLintsConfig: page.config,
      );

      expect(
        codes,
        contains(rule),
        reason:
            'The `## Don\'t` example on ${page.path} is not reported by '
            '$rule, so the page teaches a shape the rule does not catch. '
            'Fix the example to match what the rule actually reports '
            '(lib/src/rules/$rule.dart), or correct the rule. '
            'Diagnostics actually reported: $codes',
      );
    });
  }
}

const _minimumCheckedPages = 171;

String? _skipReason(_Page page) {
  if (_unenforceable.containsKey(page.rule)) return _unenforceable[page.rule];

  final snippet = page.dontSnippet;
  if (snippet == null) return 'no Dart snippet under the Don\'t heading';

  final unstubbed = _unstubbedPackage(snippet);
  if (unstubbed != null) return 'needs a package:$unstubbed stub';

  // Edge case: either check alone is wrong; rule source over-skips, the snippet misses EdgeInsets
  if (_needsRealFlutter(page.rule) && _beyondFlutterStub.hasMatch(snippet)) {
    return 'rule keys on package:flutter types the stub does not carry';
  }

  final ghost = _undeclaredStandIn(snippet);
  if (ghost != null) return 'uses undeclared `$ghost`';

  final match = _beyondMockSdk.firstMatch(
    _withStringsAndCommentsBlanked(snippet),
  );
  final missing = match?.group(1) ?? match?.group(2);
  if (missing != null) return '`$missing` is absent from the mock SDK';

  if (_wrap(snippet, page) == null) {
    return 'snippet does not parse in any frame';
  }

  return null;
}

const _unenforceable = <String, String>{
  'match_lib_folder_structure': 'diagnoses the file path, not the source',
  'prefer_match_file_name': 'diagnoses the file path, not the source',
  'prefer_correct_test_file_name': 'diagnoses the file path, not the source',
  'require_mirror_test': 'diagnoses the absence of a sibling test file',
  'require_module_barrel':
      'needs module paths; covered by require_module_barrel_test.dart',
  'prefer_module_barrel_imports':
      'needs sibling modules; covered by prefer_module_barrel_imports_test.dart',
  'avoid_banned_names': 'config-only; needs the page\'s own entries',
  'avoid_banned_types': 'config-only; needs the page\'s own entries',
  'avoid_banned_imports': 'config-only; needs the page\'s own entries',
  'avoid_banned_annotations': 'config-only; needs the page\'s own entries',
  'avoid_banned_exports': 'config-only; needs the page\'s own entries',
  'banned_usage': 'config-only; needs the page\'s own entries',
  'match_pattern': 'config-only; needs the page\'s own entries',
  'avoid_ad_hoc_left_type': 'config-only; needs the page\'s own error_types',
  'match_class_name_pattern': 'config-only; needs the page\'s own pattern',
};

class _Page {
  _Page({
    required this.path,
    required this.rule,
    required this.dontSnippet,
    required this.config,
    required this.needsFlutter,
    required this.needsFpdart,
  });

  final String path;
  final String rule;
  final String? dontSnippet;

  final String? config;

  final bool needsFlutter;
  final bool needsFpdart;
}

final _title = RegExp(r'^title:\s*(\S+)\s*$', multiLine: true);

final _dontSection = RegExp(
  r"^## Don't\s*$(.*?)^## ",
  multiLine: true,
  dotAll: true,
);

final _dartFence = RegExp(
  r'^```dart[^\n]*\n(.*?)^```',
  multiLine: true,
  dotAll: true,
);

List<_Page> _rulePages() {
  final root = Directory('docs/src/content/docs/docs/rules');
  if (!root.existsSync()) return const [];

  final pages = <_Page>[];
  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.md') && !entity.path.endsWith('.mdx')) continue;

    final source = entity.readAsStringSync();
    final rule = _title.firstMatch(source)?.group(1);
    if (rule == null) continue;

    final section = _dontSection.firstMatch(source)?.group(1);
    final snippet = section == null
        ? null
        : _dartFence.firstMatch(section)?.group(1);

    pages.add(
      _Page(
        path: entity.path,
        rule: rule,
        dontSnippet: snippet,
        config: _documentedConfig(source, rule),
        needsFlutter: _mentionsFlutter(snippet),
        needsFpdart: _mentionsFpdart(snippet),
      ),
    );
  }

  pages.sort((a, b) => a.rule.compareTo(b.rule));
  return pages;
}

String? _documentedConfig(String source, String rule) {
  String? best;
  for (final match in RegExp(
    r'^```yaml[^\n]*\n# many_lints\.yaml\n(.*?)^```',
    multiLine: true,
    dotAll: true,
  ).allMatches(source)) {
    final block = match.group(1)!;
    if (!block.contains('$rule:')) continue;
    if (RegExp('$rule:\\s*false').hasMatch(block)) continue;
    if (best == null || block.length > best.length) best = block;
  }

  final inline = RegExp(
    r'With\s+`([a-z_]+):\s*([^`]+)`',
  ).firstMatch(_dontPreamble(source));
  if (inline != null) {
    return 'rules:\n  $rule:\n    enabled: true\n'
        '    ${inline.group(1)}: ${inline.group(2)!.trim()}\n';
  }

  if (best == null) return null;

  // Edge case: a supplied config replaces the default enabled: true, so options maps need the flag
  if (RegExp('$rule:\\s*true').hasMatch(best)) return best;
  if (best.contains('enabled:')) return best;

  return best.replaceFirst('$rule:\n', '$rule:\n    enabled: true\n');
}

String _dontPreamble(String source) {
  final section = _dontSection.firstMatch(source)?.group(1) ?? '';
  final fence = section.indexOf('```');
  return fence == -1 ? section : section.substring(0, fence);
}

bool _mentionsFlutter(String? snippet) =>
    snippet != null &&
    RegExp(
      r'\b(Widget|BuildContext|StatelessWidget|StatefulWidget|State<|Container|'
      r'Column|Row|Text|Padding|Scaffold|SizedBox|EdgeInsets|Key|setState)\b',
    ).hasMatch(snippet);

bool _mentionsFpdart(String? snippet) =>
    snippet != null &&
    RegExp(
      r'\b(Either|TaskEither|IOEither|Option|Task|IO|TaskOption|IOOption|'
      r'Unit|unit)\b',
    ).hasMatch(snippet);

const _unstubbed = <String, String>{
  // Edge case: anchored on Riverpod constructors, a loose *Provider match skipped pages silently
  'riverpod':
      r'@riverpod|\w*Notifier\b|\bRef\b|\bWidgetRef\b|'
      r'ConsumerWidget|ConsumerState|ProviderScope|\bref\.|\bAsyncValue\b|'
      r'\bAsyncData\b|\bAsyncLoading\b|\bAsyncError\b|'
      r'\b(?:Provider|FutureProvider|StreamProvider|StateProvider|'
      r'NotifierProvider|AsyncNotifierProvider|ChangeNotifierProvider|'
      r'StateNotifierProvider)\s*[(<.]',
  'bloc':
      r'\bBloc\b|\bCubit\b|\bemit\(|BlocProvider|BlocBuilder|'
      r'RepositoryProvider',
  'hooks': r'\bHookWidget\b|\buse[A-Z]',
  'test':
      r'\bexpect\(|\btest\(|\bgroup\(|\bsetUp\(|\bMock\b|\bFake\b|'
      r'expectLater\(',
  'equatable': r'EquatableMixin|\bEquatable\b',
};

String? _unstubbedPackage(String? snippet) {
  if (snippet == null) return null;
  for (final MapEntry(key: name, value: pattern) in _unstubbed.entries) {
    if (RegExp(pattern).hasMatch(snippet)) return name;
  }
  return null;
}

String _withStringsAndCommentsBlanked(String source) => source
    .replaceAll(RegExp(r'//[^\n]*'), '')
    .replaceAll(
      RegExp(
        r"'''[\s\S]*?'''|"
        r'"""[\s\S]*?"""',
      ),
      "''",
    )
    .replaceAll(RegExp(r"'(?:\\.|[^'\\\n])*'"), "''")
    .replaceAll(RegExp(r'"(?:\\.|[^"\\\n])*"'), '""');

String? _undeclaredStandIn(String rawSnippet) {
  final snippet = _withStringsAndCommentsBlanked(rawSnippet);
  const seeds = {
    'repository',
    'logger',
    'client',
    'api',
    'db',
    'database',
    'service',
    'controller',
    'notifier',
    'bloc',
    'cubit',
    'store',
    'cache',
    'someProvider',
    'myProvider',
    'testOption',
    'market',
  };

  for (final seed in seeds) {
    if (!RegExp('(?<![.\\w\$])$seed(?![\\w\$])').hasMatch(snippet)) continue;
    final declared = RegExp(
      '(?:'
      r'(?:final|var|const|late)\s+(?:[\w<>,?\[\] ]+\s+)?'
      '$seed\\b'
      '|'
      r'\b[A-Z][\w<>,?\[\]]*\??\s+'
      '$seed\\s*[,)=;{]'
      '|'
      'class\\s+$seed\\b'
      '|'
      '$seed\\s*\\([^)]*\\)\\s*(?:async\\s*)?[{=]'
      ')',
    );
    if (!declared.hasMatch(snippet)) return seed;
  }
  return null;
}

bool _needsRealFlutter(String rule) {
  final source = File('lib/src/rules/$rule.dart');
  if (!source.existsSync()) return false;
  final text = source.readAsStringSync();

  if (_pinsFlutter(text)) return true;

  for (final match in RegExp(
    r"""import\s+'(?:\./)?\.\./([a-z_]+\.dart)'""",
  ).allMatches(text)) {
    final helper = File('lib/src/${match.group(1)}');
    if (helper.existsSync() && _pinsFlutter(helper.readAsStringSync())) {
      return true;
    }
  }
  return false;
}

bool _pinsFlutter(String source) =>
    source.contains('package:flutter') ||
    source.contains("packageName: 'flutter'");

final _beyondFlutterStub = RegExp(
  r'\b(Colors?|Sliver\w+|Theme\w*|Navigator|MediaQuery|Scaffold|AppBar|Icon\w*|'
  r'Image|Border\w*|BoxDecoration|Decoration|Align|Center|Expanded|Flexible|'
  r'InheritedWidget|Transform|ColoredBox|GestureDetector|Form\w*|EdgeInsets\w*|'
  r'AnimationController|TabController|FocusNode|ScrollController|Spacer|'
  r'CircularProgressIndicator|ValueNotifier|ChangeNotifier|GlobalKey|'
  r'TextEditingController|PageController|FutureBuilder|StreamBuilder|'
  r'RenderObject\w*|ThemeMode|Opacity|Padding|Container|SizedBox|Column|Row|'
  r'Wrap|Flex|Stack|InkWell|RichText|TextSpan|WidgetsBinding)\b',
);

final _beyondMockSdk = RegExp(
  r'\.(ignore)\(|\b(StreamController|ReceivePort)\b',
);

const _preamble = '''
final List<String> items = <String>[];
final List<String> users = <String>[];
final List<String> products = <String>[];
final Map<String, String> config = <String, String>{};
void handle(Object? value) {}
void doWork() {}
''';

String? _wrap(String snippet, _Page page) {
  final imports = StringBuffer();
  if (page.needsFlutter) {
    imports.writeln("import 'package:flutter/flutter.dart';");
  }
  if (page.needsFpdart) imports.writeln("import 'package:fpdart/fpdart.dart';");

  final snippetImports = <String>[];
  final rest = <String>[];
  for (final line in snippet.trimRight().split('\n')) {
    (line.trimLeft().startsWith('import ') ? snippetImports : rest).add(line);
  }
  imports.writeAll(snippetImports, '\n');
  if (snippetImports.isNotEmpty) imports.writeln();

  final body = rest.join('\n').trim();
  final candidates = <String>[
    body,
    'void _snippet() {\n$body\n}',
    'Future<void> _snippet() async {\n$body\n}',
    'class _Snippet {\n$body\n}',
    'final _snippet = $body;',
    'void _snippet() {\n_call($body);\n}',
  ];

  for (final candidate in candidates) {
    final source = '$imports\n$_preamble\n$candidate\n';
    if (_parses(source)) return source;
  }
  return null;
}

bool _parses(String source) {
  final result = parseString(
    content: source,
    featureSet: FeatureSet.latestLanguageVersion(),
    throwIfDiagnostics: false,
  );
  return result.errors.isEmpty;
}
