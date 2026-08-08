// ignore_for_file: implementation_imports
import 'dart:async';

import 'package:analysis_server_plugin/src/plugin_server.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_constants.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as protocol;
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart'
    as protocol;
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:many_lints/many_lints.dart';
import 'package:many_lints/src/rule_config.dart';
import 'package:test/test.dart';

/// A file importing `dart:async`, which resolves under `createMockSdk`.
///
/// Deliberately pure Dart: rules keyed on a pub package do not resolve in the
/// mock SDK, and a rule that never fires makes every "silenced" assertion pass
/// vacuously.
const _importCode = '''
import 'dart:async';

Future<void> f() async {}
''';

const _exportCode = '''
export 'dart:async';
''';

const _bannedTypeCode = '''
class LegacyUser {}

void f(LegacyUser user) {}
''';

const _bannedNameCode = '''
void f() {
  final data = 1;
  print(data);
}
''';

const _annotationCode = '''
class C {
  @deprecated
  void old() {}
}
''';

const _usageCode = '''
void f() {
  final at = DateTime.now();
  print(at);
}
''';

void main() {
  late _Harness harness;

  setUp(() async {
    // The loader cache is static and survives across tests.
    ConfigLoader.clearCache();
    harness = _Harness();
    await harness.setUp();
  });

  tearDown(() async => harness.tearDown());

  group('avoid_banned_imports', () {
    test('reports nothing when unconfigured', () async {
      // The whole family is config-driven: installing the package must not
      // ban anything on its own.
      final codes = await harness.codesFor(_importCode);

      expect(codes, isNot(contains('avoid_banned_imports')));
    });

    test('reports a denied import', () async {
      final codes = await harness.codesFor(
        _importCode,
        config: '''
rules:
  avoid_banned_imports:
    banned:
      - deny: ['dart:async']
''',
      );

      expect(codes, contains('avoid_banned_imports'));
    });

    test('leaves an import that is not denied alone', () async {
      final codes = await harness.codesFor(
        _importCode,
        config: '''
rules:
  avoid_banned_imports:
    banned:
      - deny: ['dart:io']
''',
      );

      expect(codes, isNot(contains('avoid_banned_imports')));
    });

    test('an in-scope path restriction still reports', () async {
      final codes = await harness.codesFor(
        _importCode,
        config: '''
rules:
  avoid_banned_imports:
    banned:
      - deny: ['dart:async']
        in: ['lib/**']
''',
      );

      expect(codes, contains('avoid_banned_imports'));
    });

    test('an out-of-scope path restriction does not report', () async {
      // Asymmetric to the test above: same entry, different glob, so silence
      // here proves the scoping worked rather than that nothing ran.
      final codes = await harness.codesFor(
        _importCode,
        config: '''
rules:
  avoid_banned_imports:
    banned:
      - deny: ['dart:async']
        in: ['test/**']
''',
      );

      expect(codes, isNot(contains('avoid_banned_imports')));
    });

    test('deny_pattern matches', () async {
      final codes = await harness.codesFor(
        _importCode,
        config: r'''
rules:
  avoid_banned_imports:
    banned:
      - deny_pattern: ['dart:.*']
''',
      );

      expect(codes, contains('avoid_banned_imports'));
    });

    test('deny does not match a substring', () async {
      final codes = await harness.codesFor(
        _importCode,
        config: '''
rules:
  avoid_banned_imports:
    banned:
      - deny: ['async']
''',
      );

      expect(codes, isNot(contains('avoid_banned_imports')));
    });

    test('the message carries the configured explanation', () async {
      final errors = await harness.analyze(
        _importCode,
        config: '''
rules:
  avoid_banned_imports:
    banned:
      - deny: ['dart:async']
        message: 'Use the scheduler instead.'
''',
      );

      final message = errors
          .firstWhere((e) => e.code == 'avoid_banned_imports')
          .message;
      expect(message, contains('dart:async'));
      expect(message, contains('Use the scheduler instead.'));
    });

    test('omitting message leaves no trailing whitespace', () async {
      final errors = await harness.analyze(
        _importCode,
        config: '''
rules:
  avoid_banned_imports:
    banned:
      - deny: ['dart:async']
''',
      );

      final message = errors
          .firstWhere((e) => e.code == 'avoid_banned_imports')
          .message;
      expect(message, isNot(endsWith(' ')));
    });

    test('exclude silences the rule', () async {
      final codes = await harness.codesFor(
        _importCode,
        config: '''
rules:
  avoid_banned_imports:
    exclude:
      - lib/**
    banned:
      - deny: ['dart:async']
''',
      );

      expect(codes, isNot(contains('avoid_banned_imports')));
    });

    test('a non-matching exclude leaves the rule reporting', () async {
      final codes = await harness.codesFor(
        _importCode,
        config: '''
rules:
  avoid_banned_imports:
    exclude:
      - test/**
    banned:
      - deny: ['dart:async']
''',
      );

      expect(codes, contains('avoid_banned_imports'));
    });

    test('is configurable via the analysis_options section', () async {
      final codes = await harness.codesFor(
        _importCode,
        optionsSection: '''
many_lints:
  rules:
    avoid_banned_imports:
      banned:
        - deny: ['dart:async']
''',
      );

      expect(codes, contains('avoid_banned_imports'));
    });
  });

  group('avoid_banned_exports', () {
    test('reports nothing when unconfigured', () async {
      final codes = await harness.codesFor(_exportCode);

      expect(codes, isNot(contains('avoid_banned_exports')));
    });

    test('reports a denied export', () async {
      final codes = await harness.codesFor(
        _exportCode,
        config: '''
rules:
  avoid_banned_exports:
    banned:
      - deny: ['dart:async']
''',
      );

      expect(codes, contains('avoid_banned_exports'));
    });

    test('an import config does not drive the export rule', () async {
      // The two rules read their own config, so banning an import must not
      // silently ban the matching export.
      final codes = await harness.codesFor(
        _exportCode,
        config: '''
rules:
  avoid_banned_imports:
    banned:
      - deny: ['dart:async']
''',
      );

      expect(codes, isNot(contains('avoid_banned_exports')));
    });
  });

  group('avoid_banned_types', () {
    test('reports nothing when unconfigured', () async {
      final codes = await harness.codesFor(_bannedTypeCode);

      expect(codes, isNot(contains('avoid_banned_types')));
    });

    test('reports a denied type', () async {
      final codes = await harness.codesFor(
        _bannedTypeCode,
        config: '''
rules:
  avoid_banned_types:
    banned:
      - deny: ['LegacyUser']
''',
      );

      expect(codes, contains('avoid_banned_types'));
    });

    test('leaves a type that is not denied alone', () async {
      final codes = await harness.codesFor(
        _bannedTypeCode,
        config: '''
rules:
  avoid_banned_types:
    banned:
      - deny: ['SomethingElse']
''',
      );

      expect(codes, isNot(contains('avoid_banned_types')));
    });

    test('matches a type used as a type argument', () async {
      final codes = await harness.codesFor(
        '''
class LegacyUser {}

void f(List<LegacyUser> users) {}
''',
        config: '''
rules:
  avoid_banned_types:
    banned:
      - deny: ['LegacyUser']
''',
      );

      expect(codes, contains('avoid_banned_types'));
    });

    test('a package-qualified entry matches the declaring library', () async {
      final codes = await harness.codesFor(
        _importCode,
        config: '''
rules:
  avoid_banned_types:
    banned:
      - deny: ['dart:async#Future']
''',
      );

      expect(codes, contains('avoid_banned_types'));
    });

    test('a wrong-library qualification does not match', () async {
      // Asymmetric to the test above: the bare name would match, so silence
      // here proves the qualification is actually being checked.
      final codes = await harness.codesFor(
        _importCode,
        config: '''
rules:
  avoid_banned_types:
    banned:
      - deny: ['dart:io#Future']
''',
      );

      expect(codes, isNot(contains('avoid_banned_types')));
    });
  });

  group('avoid_banned_names', () {
    test('reports nothing when unconfigured', () async {
      final codes = await harness.codesFor(_bannedNameCode);

      expect(codes, isNot(contains('avoid_banned_names')));
    });

    test('reports a denied variable name', () async {
      final codes = await harness.codesFor(
        _bannedNameCode,
        config: '''
rules:
  avoid_banned_names:
    banned:
      - deny: [data]
''',
      );

      expect(codes, contains('avoid_banned_names'));
    });

    test('reports a denied class name', () async {
      final codes = await harness.codesFor(
        'class Manager {}',
        config: '''
rules:
  avoid_banned_names:
    banned:
      - deny: [Manager]
''',
      );

      expect(codes, contains('avoid_banned_names'));
    });

    test('reports a denied parameter name', () async {
      final codes = await harness.codesFor(
        'void f(int data) => print(data);',
        config: '''
rules:
  avoid_banned_names:
    banned:
      - deny: [data]
''',
      );

      expect(codes, contains('avoid_banned_names'));
    });

    test('reports each declaration once, not each reference', () async {
      // The rule deliberately checks declarations only: a reference is not
      // separately fixable, and reporting both buries the actionable line.
      final errors = await harness.analyze(
        '''
void f() {
  final data = 1;
  print(data);
  print(data);
}
''',
        config: '''
rules:
  avoid_banned_names:
    banned:
      - deny: [data]
''',
      );

      expect(errors.where((e) => e.code == 'avoid_banned_names'), hasLength(1));
    });

    test('deny_pattern matches a name suffix convention', () async {
      final codes = await harness.codesFor(
        'class UserImpl {}',
        config: r'''
rules:
  avoid_banned_names:
    banned:
      - deny_pattern: ['.*Impl']
''',
      );

      expect(codes, contains('avoid_banned_names'));
    });

    test('a pattern anchored to the whole name does not over-match', () async {
      final codes = await harness.codesFor(
        'class ImplementationDetail {}',
        config: r'''
rules:
  avoid_banned_names:
    banned:
      - deny_pattern: ['.*Impl']
''',
      );

      expect(codes, isNot(contains('avoid_banned_names')));
    });
  });

  group('avoid_banned_annotations', () {
    test('reports nothing when unconfigured', () async {
      final codes = await harness.codesFor(_annotationCode);

      expect(codes, isNot(contains('avoid_banned_annotations')));
    });

    test('reports a denied annotation', () async {
      final codes = await harness.codesFor(
        _annotationCode,
        config: '''
rules:
  avoid_banned_annotations:
    banned:
      - deny: [deprecated]
''',
      );

      expect(codes, contains('avoid_banned_annotations'));
    });

    test('leaves an annotation that is not denied alone', () async {
      final codes = await harness.codesFor(
        _annotationCode,
        config: '''
rules:
  avoid_banned_annotations:
    banned:
      - deny: [visibleForTesting]
''',
      );

      expect(codes, isNot(contains('avoid_banned_annotations')));
    });

    test('scoping by path applies to annotations too', () async {
      final codes = await harness.codesFor(
        _annotationCode,
        config: '''
rules:
  avoid_banned_annotations:
    banned:
      - deny: [deprecated]
        in: ['test/**']
''',
      );

      expect(codes, isNot(contains('avoid_banned_annotations')));
    });
  });

  group('banned_usage', () {
    test('reports nothing when unconfigured', () async {
      final codes = await harness.codesFor(_usageCode);

      expect(codes, isNot(contains('banned_usage')));
    });

    test('reports a denied constructor', () async {
      final codes = await harness.codesFor(
        _usageCode,
        config: '''
rules:
  banned_usage:
    banned:
      - deny: ['DateTime.now']
''',
      );

      expect(codes, contains('banned_usage'));
    });

    test('leaves a member that is not denied alone', () async {
      final codes = await harness.codesFor(
        _usageCode,
        config: '''
rules:
  banned_usage:
    banned:
      - deny: ['DateTime.parse']
''',
      );

      expect(codes, isNot(contains('banned_usage')));
    });

    test('a bare member name bans it on any type', () async {
      final codes = await harness.codesFor(
        _usageCode,
        config: '''
rules:
  banned_usage:
    banned:
      - deny: [now]
''',
      );

      expect(codes, contains('banned_usage'));
    });

    test('matches a member declared on a supertype', () async {
      // `first` is declared on Iterable, so a List receiver must still match
      // an `Iterable.first` entry.
      final codes = await harness.codesFor(
        '''
int f(List<int> xs) => xs.first;
''',
        config: '''
rules:
  banned_usage:
    banned:
      - deny: ['Iterable.first']
''',
      );

      expect(codes, contains('banned_usage'));
    });

    test('a wrong owning type does not match', () async {
      final codes = await harness.codesFor(
        '''
int f(List<int> xs) => xs.first;
''',
        config: '''
rules:
  banned_usage:
    banned:
      - deny: ['String.first']
''',
      );

      expect(codes, isNot(contains('banned_usage')));
    });

    test('the message names the qualified member', () async {
      final errors = await harness.analyze(
        _usageCode,
        config: '''
rules:
  banned_usage:
    banned:
      - deny: ['DateTime.now']
        message: 'Inject a clock.'
''',
      );

      final message = errors
          .firstWhere((e) => e.code == 'banned_usage')
          .message;
      expect(message, contains('DateTime.now'));
      expect(message, contains('Inject a clock.'));
    });
  });

  group('config precedence', () {
    test('many_lints.yaml wins outright over the options section', () async {
      // A merge would ban both URIs; the dedicated file must be used alone.
      final codes = await harness.codesFor(
        _importCode,
        config: '''
rules:
  avoid_banned_imports:
    banned:
      - deny: ['dart:io']
''',
        optionsSection: '''
many_lints:
  rules:
    avoid_banned_imports:
      banned:
        - deny: ['dart:async']
''',
      );

      expect(codes, isNot(contains('avoid_banned_imports')));
    });
  });
}

class _Harness with ResourceProviderMixin {
  final channel = _FakeChannel();

  late final PluginServer pluginServer;

  String get byteStoreRoot => convertPath('/byteStore');

  String get packagePath => convertPath('/package');

  String get sdkRoot => convertPath('/sdk');

  /// The diagnostic codes reported for [content].
  Future<Iterable<String>> codesFor(
    String content, {
    String? config,
    String? optionsSection,
  }) async {
    final errors = await analyze(
      content,
      config: config,
      optionsSection: optionsSection,
    );
    return errors.map((e) => e.code);
  }

  Future<List<protocol.AnalysisError>> analyze(
    String content, {
    String? config,
    String? optionsSection,
    String fileName = 'test.dart',
  }) async {
    final filePath = join(packagePath, 'lib', fileName);

    newAnalysisOptionsYamlFile(packagePath, '''
plugins:
  many_lints:
    path: /many_lints
${optionsSection ?? ''}''');

    if (config != null) {
      newFile(join(packagePath, ConfigLoader.fileName), config);
    }
    newFile(filePath, content);

    final errors = channel.notifications
        .where((n) => n.event == protocol.ANALYSIS_NOTIFICATION_ERRORS)
        .map(protocol.AnalysisErrorsParams.fromNotification)
        .where((params) => params.file == filePath)
        .map((params) => params.errors)
        .first;

    await channel.sendRequest(
      protocol.AnalysisSetAnalysisRootsParams([packagePath], []),
    );

    return errors.timeout(const Duration(seconds: 10));
  }

  Future<void> setUp() async {
    createMockSdk(resourceProvider: resourceProvider, root: getFolder(sdkRoot));

    pluginServer = PluginServer.new2(
      resourceProvider: resourceProvider,
      plugins: {'many_lints': ManyLintsPlugin()},
    );

    await pluginServer.initialize();
    pluginServer.start(channel);
    await pluginServer.handlePluginVersionCheck(
      protocol.PluginVersionCheckParams(byteStoreRoot, sdkRoot, '0.0.1'),
    );
  }

  Future<void> tearDown() async {
    // Analysis is async through the driver scheduler; closing the channel
    // first makes background analysis report to a closed channel.
    await pluginServer.waitForIdle();
    channel.close();
  }
}

class _FakeChannel implements PluginCommunicationChannel {
  final _completers = <String, Completer<protocol.Response>>{};
  final _notificationsController =
      StreamController<protocol.Notification>.broadcast();

  void Function(protocol.Request)? _onRequest;
  int _idCounter = 0;

  Stream<protocol.Notification> get notifications =>
      _notificationsController.stream;

  @override
  void close() {
    _notificationsController.close();
  }

  @override
  void listen(
    void Function(protocol.Request request)? onRequest, {
    void Function()? onDone,
    Function? onError,
    Function? onNotification,
  }) {
    _onRequest = onRequest;
  }

  @override
  void sendNotification(protocol.Notification notification) {
    if (_notificationsController.isClosed) return;
    _notificationsController.add(notification);
  }

  Future<protocol.Response> sendRequest(protocol.RequestParams params) {
    final onRequest = _onRequest;
    if (onRequest == null) {
      fail('Plugin channel has not started listening.');
    }

    final id = (_idCounter++).toString();
    final request = params.toRequest(id);
    final completer = Completer<protocol.Response>();
    _completers[request.id] = completer;
    onRequest(request);
    return completer.future;
  }

  @override
  void sendResponse(protocol.Response response) {
    _completers.remove(response.id)?.complete(response);
  }
}
