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

/// A skipped test, with a reason string.
const _skipWithReasonCode = '''
void test(String description, void Function() body, {Object? skip}) {}

void main() {
  test('handles a timeout', () {}, skip: 'flaky on CI');
}
''';

/// A skipped test with no reason, which no option should ever permit.
const _skipBareCode = '''
void test(String description, void Function() body, {Object? skip}) {}

void main() {
  test('handles a timeout', () {}, skip: true);
}
''';

/// A catch clause whose body holds only a comment.
const _commentedCatchCode = '''
void doSomething() {}

void main() {
  try {
    doSomething();
  } catch (e) {
    // Ignored, really.
  }
}
''';

/// A catch clause with nothing at all in it.
const _bareCatchCode = '''
void doSomething() {}

void main() {
  try {
    doSomething();
  } catch (e) {}
}
''';

/// `exit()` in ordinary library code.
const _exitCode = '''
import 'dart:io';

void upload() {
  exit(3);
}
''';

/// A bare TODO with no tracked reference.
const _bareTodoCode = '''
void upload() {
  // TODO: handle the 409 conflict case
}
''';

/// A TODO naming an issue, which the default `require_reference` accepts.
const _referencedTodoCode = '''
void upload() {
  // TODO(#42): handle the 409 conflict case
}
''';

/// A throw of a bare `Exception`.
const _bareExceptionCode = '''
void upload() {
  throw Exception('upload failed');
}
''';

/// A throw of `FormatException`, which the default allow list permits.
const _formatExceptionCode = '''
void upload() {
  throw FormatException('bad manifest');
}
''';

void main() {
  group('quality-gate rule options', () {
    late _QualityGateHarness harness;

    setUp(() async {
      ConfigLoader.clearCache();
      harness = _QualityGateHarness();
      await harness.setUp();
    });

    tearDown(() async => harness.tearDown());

    group('avoid_skipped_tests', () {
      // The positive control. Without this, every "excluded" assertion below
      // could pass simply because the rule never ran.
      test('reports a skip with a reason by default', () async {
        final errors = await harness.analyze(
          _skipWithReasonCode,
          config: 'preset: recommended',
        );

        expect(errors.map((e) => e.code), contains('avoid_skipped_tests'));
      });

      test('allow_reason permits a documented skip', () async {
        final errors = await harness.analyze(
          _skipWithReasonCode,
          config: '''
rules:
  avoid_skipped_tests:
    allow_reason: true
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('avoid_skipped_tests')),
        );
      });

      // The asymmetric positive: the option must not switch the rule off.
      test('allow_reason still reports a bare skip', () async {
        final errors = await harness.analyze(
          _skipBareCode,
          config: '''
rules:
  avoid_skipped_tests:
    allow_reason: true
''',
        );

        expect(errors.map((e) => e.code), contains('avoid_skipped_tests'));
      });
    });

    group('avoid_empty_catch', () {
      test('reports a comment-only catch by default', () async {
        final errors = await harness.analyze(
          _commentedCatchCode,
          config: 'preset: recommended',
        );

        expect(errors.map((e) => e.code), contains('avoid_empty_catch'));
      });

      test('allow_with_comment permits a commented catch', () async {
        final errors = await harness.analyze(
          _commentedCatchCode,
          config: '''
rules:
  avoid_empty_catch:
    allow_with_comment: true
''',
        );

        expect(errors.map((e) => e.code), isNot(contains('avoid_empty_catch')));
      });

      test('allow_with_comment still reports a bare empty catch', () async {
        final errors = await harness.analyze(
          _bareCatchCode,
          config: '''
rules:
  avoid_empty_catch:
    allow_with_comment: true
''',
        );

        expect(errors.map((e) => e.code), contains('avoid_empty_catch'));
      });
    });

    group('avoid_exit_outside_entrypoint', () {
      test('reports exit in lib by default', () async {
        final errors = await harness.analyze(
          _exitCode,
          config: 'preset: recommended',
        );

        expect(
          errors.map((e) => e.code),
          contains('avoid_exit_outside_entrypoint'),
        );
      });

      test('allow_in permits the configured location', () async {
        final errors = await harness.analyze(
          _exitCode,
          fileName: 'main.dart',
          config: '''
rules:
  avoid_exit_outside_entrypoint:
    allow_in:
      - lib/main.dart
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('avoid_exit_outside_entrypoint')),
        );
      });

      test('allow_in still reports elsewhere', () async {
        final errors = await harness.analyze(
          _exitCode,
          fileName: 'upload.dart',
          config: '''
rules:
  avoid_exit_outside_entrypoint:
    allow_in:
      - lib/main.dart
''',
        );

        expect(
          errors.map((e) => e.code),
          contains('avoid_exit_outside_entrypoint'),
        );
      });
    });

    group('avoid_todo_comments', () {
      test('reports a bare TODO by default', () async {
        final errors = await harness.analyze(
          _bareTodoCode,
          config: 'preset: opinionated',
        );

        expect(errors.map((e) => e.code), contains('avoid_todo_comments'));
      });

      // The default `require_reference: true` is what keeps the rule usable.
      test('a referenced TODO passes by default', () async {
        final errors = await harness.analyze(
          _referencedTodoCode,
          config: 'preset: opinionated',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('avoid_todo_comments')),
        );
      });

      test('require_reference false reports even a referenced TODO', () async {
        final errors = await harness.analyze(
          _referencedTodoCode,
          config: '''
rules:
  avoid_todo_comments:
    require_reference: false
''',
        );

        expect(errors.map((e) => e.code), contains('avoid_todo_comments'));
      });

      test('markers narrows which words count', () async {
        final errors = await harness.analyze(
          _bareTodoCode,
          config: '''
rules:
  avoid_todo_comments:
    markers:
      - FIXME
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('avoid_todo_comments')),
        );
      });
    });

    group('prefer_typed_exceptions', () {
      test('reports a bare Exception by default', () async {
        final errors = await harness.analyze(
          _bareExceptionCode,
          config: 'preset: recommended',
        );

        expect(errors.map((e) => e.code), contains('prefer_typed_exceptions'));
      });

      test('an allowed SDK type passes by default', () async {
        final errors = await harness.analyze(
          _formatExceptionCode,
          config: 'preset: recommended',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('prefer_typed_exceptions')),
        );
      });

      test('allow replaces the default list', () async {
        final errors = await harness.analyze(
          _formatExceptionCode,
          config: '''
rules:
  prefer_typed_exceptions:
    allow:
      - StateError
''',
        );

        expect(errors.map((e) => e.code), contains('prefer_typed_exceptions'));
      });
    });

    group('require_mirror_test', () {
      // In no preset: it must stay silent until named.
      test('is silent under every preset', () async {
        final errors = await harness.analyze(
          'class Parser {}\n',
          fileName: 'parser.dart',
          config: 'preset: pedantic',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('require_mirror_test')),
        );
      });

      test('reports once enabled by name', () async {
        final errors = await harness.analyze(
          'class Parser {}\n',
          fileName: 'parser.dart',
          config: 'rules:\n  require_mirror_test: true\n',
        );

        expect(errors.map((e) => e.code), contains('require_mirror_test'));
      });
    });
  });
}

class _QualityGateHarness with ResourceProviderMixin {
  final channel = _QualityGateChannel();

  late final PluginServer pluginServer;

  String get byteStoreRoot => convertPath('/byteStore');

  String get packagePath => convertPath('/package');

  String get sdkRoot => convertPath('/sdk');

  /// Analyzes [content], optionally writing configuration to either source.
  ///
  /// [config] is written to `many_lints.yaml`; [optionsSection] is written as
  /// a top-level `many_lints:` section inside `analysis_options.yaml`. Passing
  /// both exercises the precedence rule.
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
    await pluginServer.waitForIdle();
    channel.close();
  }
}

class _QualityGateChannel implements PluginCommunicationChannel {
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
