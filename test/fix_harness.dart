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
import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:many_lints/many_lints.dart';
import 'package:many_lints/src/rule_config.dart';
import 'package:test/test.dart';

/// Drives a real `PluginServer` so a quick fix can be checked by the text it
/// actually produces.
///
/// `analyzer_testing` has no fix test API (still true as of 0.3.4), but the
/// plugin server answers `edit.getFixes`, so the returned edit can be applied
/// to the source and compared. Without this, a fix that silently produces
/// nothing — or produces code that does not compile — looks identical to a
/// working one.
///
/// Pass [packages] to `applyFix` for rules that only match types from another
/// package; `flutterWidgets` below is a ready-made minimal `package:flutter`.
class FixHarness with ResourceProviderMixin {
  final channel = _FakeChannel();

  late final PluginServer pluginServer;

  String get byteStoreRoot => convertPath('/byteStore');

  String get filePath => join(packagePath, 'lib', 'test.dart');

  String get packagePath => convertPath('/package');

  String get sdkRoot => convertPath('/sdk');

  /// Analyses [content], applies the fix offered for [ruleName], and returns
  /// the resulting source.
  ///
  /// [packages] maps a package name to the source of its `lib/<name>.dart`,
  /// for rules that only fire on types from another package.
  ///
  /// [manyLintsConfig] is written to `many_lints.yaml` at the package root,
  /// for fixes whose behaviour depends on per-rule configuration.
  ///
  /// When it is omitted, `preset: all` is written instead. Rules are opt-in as
  /// of 1.0.0, so without a preset the rule under test never reports and there
  /// is no diagnostic for a fix to attach to. A test that passes its own
  /// config is responsible for enabling the rule it exercises.
  Future<String> applyFix(
    String content,
    String ruleName, {
    Map<String, String> packages = const {},
    String? manyLintsConfig,
  }) async {
    newAnalysisOptionsYamlFile(packagePath, '''
plugins:
  many_lints:
    path: /many_lints
''');

    newFile(
      join(packagePath, ConfigLoader.fileName),
      manyLintsConfig ?? 'preset: all\n',
    );

    final config = PackageConfigFileBuilder()
      ..add(name: 'test', rootFolder: getFolder(packagePath));
    for (final MapEntry(key: name, value: source) in packages.entries) {
      final root = convertPath('/packages/$name');
      newFile(join(root, 'lib', '$name.dart'), source);
      config.add(name: name, rootFolder: getFolder(root));
    }
    newPackageConfigJsonFileFromBuilder(packagePath, config);

    newFile(filePath, content);

    final errors = channel.notifications
        .where(
          (notification) =>
              notification.event == protocol.ANALYSIS_NOTIFICATION_ERRORS,
        )
        .map(protocol.AnalysisErrorsParams.fromNotification)
        .where((params) => params.file == filePath)
        .map((params) => params.errors)
        .first;

    await channel.sendRequest(
      protocol.AnalysisSetAnalysisRootsParams([packagePath], []),
    );

    final reported = await errors.timeout(const Duration(seconds: 30));
    final diagnostic = reported.where((e) => e.code == ruleName).firstOrNull;
    if (diagnostic == null) {
      fail(
        'No $ruleName diagnostic was reported. '
        'Got: ${reported.map((e) => e.code).toList()}',
      );
    }

    final response = await channel.sendRequest(
      protocol.EditGetFixesParams(filePath, diagnostic.location.offset),
    );
    final result = protocol.EditGetFixesResult.fromResponse(response);

    // The offset may carry diagnostics from several rules; keep only the
    // fixes attached to the one under test, and apply a single change so
    // overlapping edits from other rules cannot corrupt the output.
    //
    // The server also offers its own "Ignore ..." fixes for every diagnostic.
    // Those come first in the list and would silently pass any test that only
    // checks "something changed", so drop them and keep the rule's own fix.
    final candidates = result.fixes
        .where((errorFixes) => errorFixes.error.code == ruleName)
        .expand((errorFixes) => errorFixes.fixes)
        .where((fix) => !fix.change.message.startsWith('Ignore '))
        .toList();

    final change = candidates.firstOrNull?.change;

    if (change == null) {
      fail(
        'The $ruleName fix was not offered for this code. '
        'Only suppression fixes were available.',
      );
    }

    final edits = [
      for (final fileEdit in change.edits)
        if (fileEdit.file == filePath) ...fileEdit.edits,
    ];

    if (edits.isEmpty) {
      fail('The $ruleName fix produced no edits for this code.');
    }

    return _applyEdits(content, edits);
  }

  Future<void> setUp() async {
    // The config cache is static and keyed by package root, which every
    // harness instance reuses — without this, one test's `many_lints.yaml`
    // leaks into the next.
    ConfigLoader.clearCache();

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

  /// Applies [edits] to [content], last offset first so earlier offsets stay
  /// valid.
  String _applyEdits(String content, List<protocol.SourceEdit> edits) {
    final ordered = [...edits]..sort((a, b) => b.offset.compareTo(a.offset));

    var result = content;
    for (final edit in ordered) {
      result = result.replaceRange(
        edit.offset,
        edit.offset + edit.length,
        edit.replacement,
      );
    }
    return result;
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

const flutterWidgets = r'''
class Key {
  const Key(String value);
}

abstract class Widget {
  const Widget({Key? key});
}

class Text extends Widget {
  const Text(String data, {super.key});
}

class ListView extends Widget {
  final bool shrinkWrap;
  const ListView({
    super.key,
    this.shrinkWrap = false,
    List<Widget> children = const [],
  });
}
''';
