import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:test/test.dart';

import 'fix_harness.dart';
import 'fpdart_stub.dart';

/// Runs the `## Don't` snippet from every rule documentation page through a
/// real `PluginServer` and asserts the rule that page documents actually
/// reports on it.
///
/// Nothing else checks this. `tool/verify_documentation.dart` proves a snippet
/// *parses* — and it tries eleven wrapper contexts until one sticks, so
/// `int _useData() => useState(42);` sails through despite `useState` returning
/// `ValueNotifier<int>`. A page can therefore present, as its canonical bad
/// example, code the rule does not report at all. That is the worst failure a
/// lint page has: the reader calibrates on it and never recognises the real
/// thing.
///
/// A full read-audit in 2026-08 found this class of drift on live pages:
///
/// - `avoid_unmodified_loop_condition` showed `while (i < items.length)` while
///   its own "Known limitations" said a condition reading a property is opaque
///   and never reported. The page contradicted itself; the rule bails on
///   `hasOpaqueRead`.
/// - `avoid_deep_widget_nesting` showed a tree commented "9 levels in" that is
///   eight widgets deep, at the documented default `max_depth: 8`.
/// - `require_atomic_async_updates` showed a body with no field read *before*
///   the await, which is the only shape the rule tracks.
///
/// This is the rule-page counterpart of `docs_assist_examples_test.dart`, which
/// does the same job for the assists page.
///
/// **Adding a rule page:** nothing to do. The page is picked up automatically
/// and its Don't block is expected to report. If it legitimately cannot be
/// checked here, add it to [_unenforceable] with the reason.
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

  test('rule pages were found', () {
    // A guard against the glob silently matching nothing — a moved docs tree
    // would otherwise make this whole suite vacuously green.
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
    // The suite is only worth as much as the number of pages it actually
    // drives. Without this, stubbing gaps could swallow page after page and
    // the run would stay green while checking almost nothing.
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

/// The floor for how many pages this suite drives, raised as stubs grow.
///
/// 151 of 261 pages are checked today. The rest are skipped for reasons
/// [_skipReason] names out loud, and the `coverage` test prints every one, so
/// the gap is visible rather than implied. Most are rules keyed to Flutter,
/// Riverpod, Bloc or hooks types the stubs do not carry: widening a stub moves
/// pages from skipped to checked and this number goes up. Lowering it means
/// coverage shrank, and needs a reason.
const _minimumCheckedPages = 151;

/// Why [page] cannot be driven through the harness, or null when it can.
String? _skipReason(_Page page) {
  if (_unenforceable.containsKey(page.rule)) return _unenforceable[page.rule];

  final snippet = page.dontSnippet;
  if (snippet == null) return 'no Dart snippet under the Don\'t heading';

  final unstubbed = _unstubbedPackage(snippet);
  if (unstubbed != null) return 'needs a package:$unstubbed stub';

  // Decided from the rule's own source rather than from the snippet: a rule
  // keyed to `package:flutter` types cannot fire against the minimal stub no
  // matter how the example is written, and reading the snippet for widget
  // names misses rules like `prefer_padding_over_container` whose Don't block
  // never spells a stubbed type.
  // Two conditions, because either alone is wrong. Rule-source alone skips
  // pages that resolve fine against the stub (`avoid_catch_error` keys on
  // `dart:async#Future`, and merely imports a helper that mentions Flutter).
  // Snippet alone misses rules like `prefer_padding_over_container`, whose
  // Don't block names only `Container`, a type the stub does carry — while the
  // rule needs `EdgeInsets`, which it does not.
  if (_needsRealFlutter(page.rule) && _beyondFlutterStub.hasMatch(snippet)) {
    return 'rule keys on package:flutter types the stub does not carry';
  }

  final ghost = _ghostIdentifiers.firstMatch(snippet)?.group(1);
  if (ghost != null) return 'uses undeclared `$ghost`';

  final missing = _beyondMockSdk.firstMatch(snippet)?.group(1);
  if (missing != null) return '`$missing` is absent from the mock SDK';

  if (_wrap(snippet, page) == null) {
    return 'snippet does not parse in any frame';
  }

  return null;
}

/// Rules whose Don't block cannot be driven through the harness, with the
/// reason. Keep this list short and justified — every entry is a page nothing
/// verifies.
const _unenforceable = <String, String>{
  // Reports on the path of the file being analysed, not on its content, so a
  // snippet in a fixed `lib/test.dart` can never trigger it.
  'match_lib_folder_structure': 'diagnoses the file path, not the source',
  'prefer_match_file_name': 'diagnoses the file path, not the source',
  'prefer_correct_test_file_name': 'diagnoses the file path, not the source',
  'require_mirror_test': 'diagnoses the absence of a sibling test file',
  // Config-only rules: silent until a project names what is banned, so the
  // documented Don't block is correct but needs that page's own YAML.
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

/// A rule documentation page and the pieces of it this suite reads.
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

  /// The `many_lints.yaml` block the page documents, when it shows one.
  ///
  /// Several rules are silent until configured — `map_keys_ordering` bails on
  /// `if (configured is! String) return;` — so running their example without
  /// the page's own YAML would report nothing and look like a broken example.
  /// Taking the config from the page also means the snippet is checked against
  /// the configuration the page actually advertises.
  final String? config;

  final bool needsFlutter;
  final bool needsFpdart;
}

/// The `title:` in a page's frontmatter is the rule name.
final _title = RegExp(r'^title:\s*(\S+)\s*$', multiLine: true);

/// The first ```dart fence under a `## Don't` heading, up to the next heading.
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

/// The `# many_lints.yaml` block a page documents for its own rule.
///
/// Pages show the same options twice — once nested under `many_lints:` for
/// `analysis_options.yaml`, once at the top level for `many_lints.yaml`. Only
/// the latter is wanted, and only when it configures this page's rule.
/// Pages carry several such blocks — one just switching the rule on, one
/// showing its options. The richest is the one worth running, and `enabled:
/// true` is appended so an options-only block still turns the rule on.
String? _documentedConfig(String source, String rule) {
  String? best;
  for (final match in RegExp(
    r'^```yaml[^\n]*\n# many_lints\.yaml\n(.*?)^```',
    multiLine: true,
    dotAll: true,
  ).allMatches(source)) {
    final block = match.group(1)!;
    if (!block.contains('$rule:')) continue;
    // Skip the `false` blocks that show how to turn the rule back off.
    if (RegExp('$rule:\\s*false').hasMatch(block)) continue;
    // Prefer the richest block: one setting an option exercises more of the
    // rule than a bare `enabled: true`.
    if (best == null || block.length > best.length) best = block;
  }

  // A page whose example only makes sense under a particular setting says so
  // in prose beside it — "With `max_imports: 5`". That inline value wins over
  // the Options section, so the printed number and the checked behaviour are
  // the same thing rather than two claims that can drift apart.
  final inline = RegExp(
    r'With\s+`([a-z_]+):\s*([^`]+)`',
  ).firstMatch(_dontPreamble(source));
  if (inline != null) {
    return 'rules:\n  $rule:\n    enabled: true\n'
        '    ${inline.group(1)}: ${inline.group(2)!.trim()}\n';
  }

  if (best == null) return null;

  // `<rule>: true` is a complete block already; an options map needs the flag
  // adding, since supplying a config replaces the default `enabled: true`.
  if (RegExp('$rule:\\s*true').hasMatch(best)) return best;
  if (best.contains('enabled:')) return best;

  return best.replaceFirst('$rule:\n', '$rule:\n    enabled: true\n');
}

/// The prose between the `## Don't` heading and its first code fence.
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

/// Packages a snippet may lean on that the harness has no stub for.
///
/// A rule that matches types from an unstubbed package cannot report, so
/// asserting on it would fail for a reason that has nothing to do with the
/// page. Those pages are skipped loudly rather than failed quietly — see the
/// `unverifiable` test, which prints the list so it cannot grow unnoticed.
const _unstubbed = <String, String>{
  'riverpod':
      r'@riverpod|\bNotifier\b|\bAsyncNotifier\b|\bRef\b|\bWidgetRef\b|'
      r'ConsumerWidget|ConsumerState|ProviderScope|\bref\.|\bAsyncValue\b|'
      r'\bAsyncData\b|\bAsyncLoading\b|\bAsyncError\b|\w+Provider\b',
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

/// Identifiers a snippet uses without declaring them.
///
/// This matters more than it looks. Most rules gate on a resolved type —
/// `avoid_catch_error` checks `node.realTarget?.staticType` against
/// `dart:async#Future` — so a receiver that resolves to nothing makes the rule
/// correctly stay silent, and an assertion here would be blaming the page for
/// the snippet's missing context rather than for its content.
///
/// It is also the machine-checkable form of the "ghost helper" complaint: a
/// snippet calling `repository.fetch()` with no `repository` in sight is
/// exactly what a reader cannot follow either. Pages listed here are the
/// backlog for the rewrite; as ghosts are replaced with real declarations, the
/// pages leave this list and start being verified.
final _ghostIdentifiers = RegExp(
  r'(?<![.\w$])(repository|logger|client|api|db|database|service|'
  r'controller|notifier|bloc|cubit|store|cache|'
  r'someProvider|myProvider|testOption|market)(?![\w$])',
);

/// Whether the rule's own source pins `package:flutter` types.
///
/// Read from `lib/src/rules/<rule>.dart` rather than guessed from the snippet,
/// so a rule whose example never names a widget is still recognised.
bool _needsRealFlutter(String rule) {
  final source = File('lib/src/rules/$rule.dart');
  if (!source.existsSync()) return false;
  final text = source.readAsStringSync();

  if (_pinsFlutter(text)) return true;

  // Most Flutter rules never name the package: they import a shared checker
  // file and use `containerChecker` and friends, each declared with
  // `packageName: 'flutter'`. Following those imports one level is what makes
  // the difference between skipping 14 pages and skipping the 60 that really
  // cannot run against the stub.
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

/// Flutter types the minimal stub does not carry.
///
/// `flutterWidgets` in the harness declares a handful — Widget, Text, ListView
/// and friends. A snippet naming anything else cannot resolve, so the rule
/// stays silent for want of a type rather than because the example is wrong.
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

/// Members `analyzer_testing`'s mock SDK does not declare.
///
/// The mock SDK is a hand-written subset, not the real one: it has
/// `abstract class Future` but no `ignore()`, for instance. A rule keyed to a
/// member that is missing there can never fire, so the snippet is skipped
/// rather than blamed. Verified by probing the harness directly, not assumed —
/// each entry here failed a minimal reproduction that should have reported.
final _beyondMockSdk = RegExp(
  r'\.(ignore)\(|\b(StreamController|ReceivePort)\b',
);

/// Declarations prepended to every snippet, so the commonest stand-ins resolve.
///
/// These are the names pages reach for as generic sample data. Declaring them
/// is strictly better than skipping the page: a skipped page is unverified,
/// while a declared name lets the rule resolve types and actually run. Keep
/// this to genuinely generic names — anything domain-specific belongs in the
/// page itself.
const _preamble = '''
final List<String> items = <String>[];
final List<String> users = <String>[];
final List<String> products = <String>[];
final Map<String, String> config = <String, String>{};
void handle(Object? value) {}
void doWork() {}
''';

/// Wraps a snippet so it stands a chance of resolving, returning null when no
/// wrapping makes it a valid library.
///
/// Pages show fragments at whatever level reads best — a bare expression, a
/// statement, a method body, a whole class — so several framings are tried and
/// the first that parses wins. This mirrors `_parsesInDocumentedContext` in
/// `tool/verify_documentation.dart`; the difference is that this suite then
/// goes on to demand a diagnostic, which is the part that catches drift.
///
/// Imports are always prepended: an unused import is harmless, a missing one
/// silences the rule and makes the assertion vacuous.
String? _wrap(String snippet, _Page page) {
  final imports = StringBuffer();
  if (page.needsFlutter) {
    imports.writeln("import 'package:flutter/flutter.dart';");
  }
  if (page.needsFpdart) imports.writeln("import 'package:fpdart/fpdart.dart';");

  // A snippet may carry its own imports — `max_imports` is about nothing else.
  // They have to lead the library, ahead of the preamble's declarations, so
  // they are lifted out rather than left where they would be a syntax error.
  final own = <String>[];
  final rest = <String>[];
  for (final line in snippet.trimRight().split('\n')) {
    (line.trimLeft().startsWith('import ') ? own : rest).add(line);
  }
  imports.writeAll(own, '\n');
  if (own.isNotEmpty) imports.writeln();

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
