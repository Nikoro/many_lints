// ignore_for_file: implementation_imports
import 'dart:async';

import 'package:analysis_server_plugin/src/plugin_server.dart';
import 'package:analyzer/src/lint/registry.dart' as analyzer_registry;
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

void main() {
  late _PluginAnalysisHarness harness;

  setUp(() async {
    harness = _PluginAnalysisHarness();
    await harness.setUp();
  });

  tearDown(() async {
    await harness.tearDown();
  });

  test('reports prefer_overriding_parent_equality when enabled', () async {
    final errors = await harness.analyze(_preferOverridingParentEqualityCode);

    expect(
      errors.map((error) => error.code),
      contains('prefer_overriding_parent_equality'),
    );
  });

  test(
    'diagnostics false disables prefer_overriding_parent_equality',
    () async {
      final errors = await harness.analyze(
        _preferOverridingParentEqualityCode,
        diagnostics: {'prefer_overriding_parent_equality': 'false'},
      );

      expect(
        errors.where(
          (error) => error.code == 'prefer_overriding_parent_equality',
        ),
        isEmpty,
      );
    },
  );

  group('suppression comments', () {
    // Plugin diagnostics are only silenced when the rule name carries the
    // plugin-name prefix: `IgnoredDiagnosticName._matches` bails out when the
    // comment's plugin name differs from the diagnostic's, and a bare comment
    // parses to a null plugin name. These tests pin that down so the docs
    // cannot drift back to claiming plugin rules ignore `// ignore`.
    Future<bool> reportsEquality(String content) async {
      final errors = await harness.analyze(content);
      return errors.any(
        (error) => error.code == 'prefer_overriding_parent_equality',
      );
    }

    test('bare ignore does not suppress', () async {
      expect(
        await reportsEquality(
          _withLineComment('// ignore: prefer_overriding_parent_equality'),
        ),
        isTrue,
      );
    });

    test('prefixed ignore suppresses', () async {
      expect(
        await reportsEquality(
          _withLineComment(
            '// ignore: many_lints/prefer_overriding_parent_equality',
          ),
        ),
        isFalse,
      );
    });

    test('bare ignore_for_file does not suppress', () async {
      expect(
        await reportsEquality(
          '// ignore_for_file: prefer_overriding_parent_equality\n'
          '$_preferOverridingParentEqualityCode',
        ),
        isTrue,
      );
    });

    test('prefixed ignore_for_file suppresses', () async {
      expect(
        await reportsEquality(
          '// ignore_for_file: many_lints/prefer_overriding_parent_equality\n'
          '$_preferOverridingParentEqualityCode',
        ),
        isFalse,
      );
    });

    test('type-based ignore requires the type= form', () async {
      expect(
        await reportsEquality(_withLineComment('// ignore: lint')),
        isTrue,
      );
      expect(
        await reportsEquality(_withLineComment('// ignore: type=lint')),
        isFalse,
      );
    });
  });

  test(
    'legacy plugin server registration does not leak warning rules globally',
    () async {
      await harness.tearDown();
      PluginServer.registries.clear();
      harness = _PluginAnalysisHarness(useNamedConstructor: false);
      await harness.setUp();

      expect(
        analyzer_registry.Registry.ruleRegistry.warningRules,
        isNot(contains('prefer_overriding_parent_equality')),
      );
    },
  );

  test(
    'legacy plugin server diagnostics false disables warning rules',
    () async {
      await harness.tearDown();
      PluginServer.registries.clear();
      harness = _PluginAnalysisHarness(useNamedConstructor: false);
      await harness.setUp();

      final errors = await harness.analyze(
        _preferOverridingParentEqualityCode,
        diagnostics: {'prefer_overriding_parent_equality': 'false'},
      );

      expect(
        errors.where(
          (error) => error.code == 'prefer_overriding_parent_equality',
        ),
        isEmpty,
      );
    },
  );
}

/// Places [comment] on the line directly above the class that triggers
/// `prefer_overriding_parent_equality`, where a line-scoped ignore applies.
String _withLineComment(String comment) =>
    _preferOverridingParentEqualityCode.replaceFirst(
      'class Child extends Parent {',
      '$comment\nclass Child extends Parent {',
    );

const _preferOverridingParentEqualityCode = r'''
class Parent {
  @override
  int get hashCode => 1;

  @override
  bool operator ==(Object other) => identical(this, other);
}

class Child extends Parent {
  final String value;
  Child(this.value);
}
''';

class _PluginAnalysisHarness with ResourceProviderMixin {
  final channel = _FakeChannel();
  final bool useNamedConstructor;

  late final PluginServer pluginServer;

  _PluginAnalysisHarness({this.useNamedConstructor = true});

  String get byteStoreRoot => convertPath('/byteStore');

  String get filePath => join(packagePath, 'lib', 'test.dart');

  String get packagePath => convertPath('/package');

  String get sdkRoot => convertPath('/sdk');

  Future<List<protocol.AnalysisError>> analyze(
    String content, {
    Map<String, String> diagnostics = const {},
  }) async {
    _writeAnalysisOptions(diagnostics);

    // Rules are opt-in as of 1.0.0. This suite is about the analyzer's own
    // `diagnostics:` key and `// ignore` comments, both of which act on a rule
    // that is already running, so the broadest preset puts the rules these
    // tests use into that state.
    newFile(join(packagePath, ConfigLoader.fileName), 'preset: opinionated\n');
    newFile(filePath, content);

    final errors = channel.notifications
        .where((notification) {
          return notification.event == protocol.ANALYSIS_NOTIFICATION_ERRORS;
        })
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

    pluginServer = useNamedConstructor
        ? PluginServer.new2(
            resourceProvider: resourceProvider,
            plugins: {'many_lints': ManyLintsPlugin()},
          )
        : PluginServer(
            resourceProvider: resourceProvider,
            plugins: [ManyLintsPlugin()],
          );

    await pluginServer.initialize();
    pluginServer.start(channel);
    await pluginServer.handlePluginVersionCheck(
      protocol.PluginVersionCheckParams(byteStoreRoot, sdkRoot, '0.0.1'),
    );
  }

  Future<void> tearDown() async {
    // Let background analysis finish before closing the channel; the
    // 0.3.18+ plugin server analyzes asynchronously via the driver
    // scheduler and would otherwise report to a closed channel.
    await pluginServer.waitForIdle();
    channel.close();
  }

  void _writeAnalysisOptions(Map<String, String> diagnostics) {
    final buffer = StringBuffer('''
plugins:
  many_lints:
    path: /many_lints
    diagnostics:
''');

    for (final MapEntry(key: name, value: enabled) in diagnostics.entries) {
      buffer.writeln('      $name: $enabled');
    }

    newAnalysisOptionsYamlFile(packagePath, buffer.toString());
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
    final completer = _completers.remove(response.id);
    completer?.complete(response);
  }
}
