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

/// A catch clause containing only `rethrow`, which `avoid_only_rethrow`
/// reports. Pure Dart, so it needs no Flutter types to resolve.
const _rethrowCode = '''
void doSomething() {}

void main() {
  try {
    doSomething();
  } catch (e) {
    rethrow;
  }
}
''';

/// The same, but with a typed `on ... catch` clause.
const _typedRethrowCode = '''
void doSomething() {}

void main() {
  try {
    doSomething();
  } on StateError catch (e) {
    rethrow;
  }
}
''';

void main() {
  group('ManyLintsConfig.parse', () {
    test('parses exclude patterns and free-form options', () {
      final config = ManyLintsConfig.parse('''
rules:
  avoid_border_all:
    exclude:
      - test/**
      - "**/*.g.dart"
    only_const_context: true
    max_count: 3
    names:
      - a
      - b
''');

      final rule = config.forRule('avoid_border_all');
      expect(rule.exclude, ['test/**', '**/*.g.dart']);
      expect(
        rule.boolOption('only_const_context', defaultValue: false),
        isTrue,
      );
      expect(rule.intOption('max_count', defaultValue: 0), 3);
      expect(rule.stringListOption('names'), ['a', 'b']);
    });

    test('returns defaults for absent rules and options', () {
      final config = ManyLintsConfig.parse('rules:\n  other_rule:\n    x: 1\n');

      final rule = config.forRule('avoid_border_all');
      expect(rule.exclude, isEmpty);
      expect(rule.boolOption('only_const_context', defaultValue: true), isTrue);
      expect(rule.intOption('missing', defaultValue: 7), 7);
    });

    test('returns defaults when an option has the wrong type', () {
      final config = ManyLintsConfig.parse('''
rules:
  avoid_border_all:
    only_const_context: "not a bool"
''');

      final rule = config.forRule('avoid_border_all');
      expect(
        rule.boolOption('only_const_context', defaultValue: false),
        isFalse,
      );
    });

    test('malformed yaml degrades to empty instead of throwing', () {
      final config = ManyLintsConfig.parse('rules: [unclosed');
      expect(config.forRule('avoid_border_all').exclude, isEmpty);
    });

    test('non-map document degrades to empty', () {
      expect(
        ManyLintsConfig.parse('just a string').forRule('x').exclude,
        isEmpty,
      );
    });
  });

  group('ManyLintsConfig.parseOptionsFile', () {
    test('reads rules nested under the many_lints section', () {
      final config = ManyLintsConfig.parseOptionsFile('''
analyzer:
  exclude:
    - build/**

many_lints:
  rules:
    avoid_only_rethrow:
      exclude:
        - test/**
      ignore_typed_catches: true
''');

      final rule = config.forRule('avoid_only_rethrow');
      expect(rule.exclude, ['test/**']);
      expect(
        rule.boolOption('ignore_typed_catches', defaultValue: false),
        isTrue,
      );
    });

    test('yields empty when the many_lints section is absent', () {
      final config = ManyLintsConfig.parseOptionsFile('''
analyzer:
  exclude:
    - build/**
''');

      expect(config.forRule('avoid_only_rethrow').exclude, isEmpty);
    });

    test('ignores a root-level rules key without the section', () {
      // `rules:` at the document root belongs to many_lints.yaml, not to
      // analysis_options.yaml, and must not be picked up here.
      final config = ManyLintsConfig.parseOptionsFile('''
rules:
  avoid_only_rethrow:
    exclude:
      - test/**
''');

      expect(config.forRule('avoid_only_rethrow').exclude, isEmpty);
    });
  });

  group('end-to-end through PluginServer', () {
    late _ConfigHarness harness;

    setUp(() async {
      ConfigLoader.clearCache();
      harness = _ConfigHarness();
      await harness.setUp();
    });

    tearDown(() async => harness.tearDown());

    test('reports the rule when no config file exists', () async {
      final errors = await harness.analyze(_rethrowCode);

      expect(errors.map((e) => e.code), contains('avoid_only_rethrow'));
    });

    test('exclude pattern silences the rule in a matching file', () async {
      final errors = await harness.analyze(
        _rethrowCode,
        config: '''
rules:
  avoid_only_rethrow:
    exclude:
      - lib/**
''',
      );

      expect(errors.map((e) => e.code), isNot(contains('avoid_only_rethrow')));
    });

    test('exclude pattern for another directory leaves the rule on', () async {
      final errors = await harness.analyze(
        _rethrowCode,
        config: '''
rules:
  avoid_only_rethrow:
    exclude:
      - test/**
''',
      );

      expect(errors.map((e) => e.code), contains('avoid_only_rethrow'));
    });

    test('suffix glob excludes generated files', () async {
      final errors = await harness.analyze(
        _rethrowCode,
        fileName: 'widget.g.dart',
        config: '''
rules:
  avoid_only_rethrow:
    exclude:
      - "**/*.g.dart"
''',
      );

      expect(errors.map((e) => e.code), isNot(contains('avoid_only_rethrow')));
    });

    test('exclude for one rule does not disable another rule', () async {
      final errors = await harness.analyze(
        '''
$_rethrowCode

class Base {
  @override
  bool operator ==(Object other) => true;
  @override
  int get hashCode => 0;
}

class Child extends Base {
  @override
  bool operator ==(Object other) => true;
}
''',
        config: '''
rules:
  avoid_only_rethrow:
    exclude:
      - lib/**
''',
      );

      final codes = errors.map((e) => e.code);
      expect(codes, isNot(contains('avoid_only_rethrow')));
      expect(codes, contains('prefer_overriding_parent_equality'));
    });

    test('mode option narrows what the rule reports', () async {
      final errors = await harness.analyze(
        _typedRethrowCode,
        config: '''
rules:
  avoid_only_rethrow:
    ignore_typed_catches: true
''',
      );

      expect(errors.map((e) => e.code), isNot(contains('avoid_only_rethrow')));
    });

    test('mode option leaves the default behaviour untouched', () async {
      final errors = await harness.analyze(_typedRethrowCode);

      expect(errors.map((e) => e.code), contains('avoid_only_rethrow'));
    });

    test('mode option still reports the cases it does not exempt', () async {
      final errors = await harness.analyze(
        _rethrowCode,
        config: '''
rules:
  avoid_only_rethrow:
    ignore_typed_catches: true
''',
      );

      expect(errors.map((e) => e.code), contains('avoid_only_rethrow'));
    });

    test('analysis_options section configures the rule', () async {
      final errors = await harness.analyze(
        _rethrowCode,
        optionsSection: '''
many_lints:
  rules:
    avoid_only_rethrow:
      exclude:
        - lib/**
''',
      );

      expect(errors.map((e) => e.code), isNot(contains('avoid_only_rethrow')));
    });

    test('analysis_options section is not applied to other paths', () async {
      final errors = await harness.analyze(
        _rethrowCode,
        optionsSection: '''
many_lints:
  rules:
    avoid_only_rethrow:
      exclude:
        - test/**
''',
      );

      expect(errors.map((e) => e.code), contains('avoid_only_rethrow'));
    });

    test('a custom top-level section provokes no analyzer warning', () async {
      final errors = await harness.analyze(
        _rethrowCode,
        optionsSection: '''
many_lints:
  rules:
    avoid_only_rethrow:
      exclude:
        - test/**
''',
      );

      // The analyzer only validates the interior of sections it knows, so an
      // unrecognized top-level key must not yield `unsupported_option`.
      expect(errors.map((e) => e.code), isNot(contains('unsupported_option')));
    });

    group('precedence when both sources exist', () {
      test('many_lints.yaml wins over the analysis_options section', () async {
        final errors = await harness.analyze(
          _rethrowCode,
          // The dedicated file excludes this file...
          config: '''
rules:
  avoid_only_rethrow:
    exclude:
      - lib/**
''',
          // ...while the options section would not have.
          optionsSection: '''
many_lints:
  rules:
    avoid_only_rethrow:
      exclude:
        - test/**
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('avoid_only_rethrow')),
        );
      });

      test('the losing source is ignored outright, not merged', () async {
        final errors = await harness.analyze(
          _rethrowCode,
          // The dedicated file exists but excludes nothing relevant, so the
          // rule must report — proving the options section's `lib/**` was
          // discarded rather than merged in.
          config: '''
rules:
  avoid_only_rethrow:
    exclude:
      - test/**
''',
          optionsSection: '''
many_lints:
  rules:
    avoid_only_rethrow:
      exclude:
        - lib/**
''',
        );

        expect(errors.map((e) => e.code), contains('avoid_only_rethrow'));
      });
    });
  });
}

class _ConfigHarness with ResourceProviderMixin {
  final channel = _FakeChannel();

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
