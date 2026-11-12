// ignore_for_file: implementation_imports
import 'dart:async';

import 'package:analysis_server_plugin/src/plugin_server.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
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

class FixHarness with ResourceProviderMixin {
  final channel = _FakeChannel();

  late final PluginServer pluginServer;

  String get byteStoreRoot => convertPath('/byteStore');

  String get filePath => join(packagePath, 'lib', 'test.dart');

  String get packagePath => convertPath('/package');

  String get sdkRoot => convertPath('/sdk');

  Future<String> applyFix(
    String content,
    String ruleName, {
    Map<String, String> packages = const {},
    Map<String, Map<String, String>> multiFilePackages = const {},
    String? manyLintsConfig,
  }) async {
    _writePackage(
      content,
      packages: packages,
      multiFilePackages: multiFilePackages,
      manyLintsConfig: manyLintsConfig,
      ruleName: ruleName,
    );

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

    final ruleOwnFixes = _ruleOwnFixes(result, ruleName);

    final change = ruleOwnFixes.firstOrNull?.change;

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

  Future<
    ({
      String source,
      List<protocol.LinkedEditGroup> linkedGroups,
      String message,
    })
  >
  applyAssist(
    String content,
    String assistId, {
    Map<String, String> packages = const {},
    Map<String, Map<String, String>> multiFilePackages = const {},
    String? manyLintsConfig,
  }) async {
    final caret = content.indexOf('^');
    if (caret < 0) {
      fail('The assist fixture must mark the cursor with "^".');
    }
    final source = content.replaceFirst('^', '');

    _writePackage(
      source,
      packages: packages,
      multiFilePackages: multiFilePackages,
      manyLintsConfig: manyLintsConfig,
    );

    await channel.sendRequest(
      protocol.AnalysisSetAnalysisRootsParams([packagePath], []),
    );
    await pluginServer.waitForIdle();

    final response = await channel.sendRequest(
      protocol.EditGetAssistsParams(filePath, caret, 0),
    );
    final result = protocol.EditGetAssistsResult.fromResponse(response);

    final change = result.assists
        .map((assist) => assist.change)
        .where((change) => change.id == assistId)
        .firstOrNull;

    if (change == null) {
      fail(
        'The $assistId assist was not offered at this offset. '
        'Got: ${result.assists.map((a) => a.change.id).toList()}',
      );
    }

    final edits = [
      for (final fileEdit in change.edits)
        if (fileEdit.file == filePath) ...fileEdit.edits,
    ];

    if (edits.isEmpty) {
      fail('The $assistId assist produced no edits for this code.');
    }

    return (
      source: _applyEdits(source, edits),
      linkedGroups: change.linkedEditGroups,
      message: change.message,
    );
  }

  Future<List<String>> compileErrors(String source) async {
    newFile(filePath, source);
    final collection = AnalysisContextCollection(
      includedPaths: [packagePath],
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot,
    );
    try {
      final result = await collection
          .contextFor(filePath)
          .currentSession
          .getResolvedUnit(filePath);
      if (result is! ResolvedUnitResult) return ['unresolved: $result'];
      return [
        for (final diagnostic in result.diagnostics)
          if (diagnostic.severity == Severity.error)
            '${diagnostic.diagnosticCode.lowerCaseName}: ${diagnostic.message}',
      ];
    } finally {
      await collection.dispose();
    }
  }

  Future<List<String>> assistIds(
    String content, {
    Map<String, String> packages = const {},
    Map<String, Map<String, String>> multiFilePackages = const {},
    String? manyLintsConfig,
  }) async {
    final caret = content.indexOf('^');
    if (caret < 0) {
      fail('The assist fixture must mark the cursor with "^".');
    }

    _writePackage(
      content.replaceFirst('^', ''),
      packages: packages,
      multiFilePackages: multiFilePackages,
      manyLintsConfig: manyLintsConfig,
    );

    await channel.sendRequest(
      protocol.AnalysisSetAnalysisRootsParams([packagePath], []),
    );
    await pluginServer.waitForIdle();

    final response = await channel.sendRequest(
      protocol.EditGetAssistsParams(filePath, caret, 0),
    );
    final result = protocol.EditGetAssistsResult.fromResponse(response);

    return [for (final assist in result.assists) ?assist.change.id];
  }

  Future<List<String>> diagnosticsFor(
    String content,
    String ruleName, {
    Map<String, String> packages = const {},
    Map<String, Map<String, String>> multiFilePackages = const {},
    List<String> enabledRules = const [],
    String? manyLintsConfig,
  }) async {
    final rules = {ruleName, ...enabledRules};
    _writePackage(
      content,
      packages: packages,
      multiFilePackages: multiFilePackages,
      manyLintsConfig:
          manyLintsConfig ??
          'rules:\n${rules.map((r) => '  $r: true\n').join()}',
      ruleName: ruleName,
    );

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
    return [for (final e in reported) e.code];
  }

  Future<void> expectNoFix(
    String content,
    String ruleName, {
    Map<String, String> packages = const {},
    Map<String, Map<String, String>> multiFilePackages = const {},
    String? manyLintsConfig,
  }) async {
    _writePackage(
      content,
      packages: packages,
      multiFilePackages: multiFilePackages,
      manyLintsConfig: manyLintsConfig,
      ruleName: ruleName,
    );

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

    final ruleOwnFixes = _ruleOwnFixes(result, ruleName);

    expect(
      ruleOwnFixes,
      isEmpty,
      reason:
          'Expected no $ruleName fix, but one was offered: '
          '${ruleOwnFixes.map((f) => f.change.message).toList()}',
    );
  }

  void _writePackage(
    String content, {
    required Map<String, String> packages,
    required Map<String, Map<String, String>> multiFilePackages,
    required String? manyLintsConfig,
    String? ruleName,
  }) {
    newAnalysisOptionsYamlFile(packagePath, '''
plugins:
  many_lints:
    path: /many_lints
''');

    newFile(
      join(packagePath, ConfigLoader.fileName),
      manyLintsConfig ??
          (ruleName == null ? 'rules: {}\n' : 'rules:\n  $ruleName: true\n'),
    );

    final config = PackageConfigFileBuilder()
      ..add(name: 'test', rootFolder: getFolder(packagePath));
    for (final MapEntry(key: name, value: source) in packages.entries) {
      final root = convertPath('/packages/$name');
      newFile(join(root, 'lib', '$name.dart'), source);
      config.add(name: name, rootFolder: getFolder(root));
    }
    for (final MapEntry(key: name, value: files) in multiFilePackages.entries) {
      final root = convertPath('/packages/$name');
      for (final MapEntry(key: path, value: source) in files.entries) {
        newFile(join(root, convertPath(path)), source);
      }
      config.add(name: name, rootFolder: getFolder(root));
    }
    newPackageConfigJsonFileFromBuilder(packagePath, config);

    newFile(filePath, content);
  }

  Future<void> setUp() async {
    // Edge case: the static config cache is keyed by the package root every harness reuses
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

  List<protocol.PrioritizedSourceChange> _ruleOwnFixes(
    protocol.EditGetFixesResult result,
    String ruleName,
  ) => result.fixes
      .where((errorFixes) => errorFixes.error.code == ruleName)
      .expand((errorFixes) => errorFixes.fixes)
      // Edge case: the server's own Ignore fixes come first and would pass any test that something changed
      .where((fix) => !fix.change.message.startsWith('Ignore '))
      .toList();

  String _applyEdits(String content, List<protocol.SourceEdit> edits) {
    final lastOffsetFirst = [...edits]
      ..sort((a, b) => b.offset.compareTo(a.offset));

    var result = content;
    for (final edit in lastOffsetFirst) {
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

abstract class BuildContext {}

abstract class StatelessWidget extends Widget {
  const StatelessWidget({super.key});
  Widget build(BuildContext context);
}

abstract class StatefulWidget extends Widget {
  const StatefulWidget({super.key});
  State<StatefulWidget> createState();
}

abstract class State<T extends StatefulWidget> {
  T get widget => throw '';
  BuildContext get context => throw '';
  bool get mounted => true;
  void initState() {}
  void didUpdateWidget(covariant T oldWidget) {}
  void didChangeDependencies() {}
  void dispose() {}
  void setState(void Function() fn) {}
  Widget build(BuildContext context);
}

class Builder extends Widget {
  const Builder({super.key, required Widget Function(BuildContext) builder});
}

class TextButton extends Widget {
  const TextButton({
    super.key,
    required void Function()? onPressed,
    required Widget child,
  });
}

class Checkbox extends Widget {
  const Checkbox({
    super.key,
    required bool value,
    required void Function(bool?)? onChanged,
  });
}

void runApp(Widget app) {}

class Color {
  const Color(int value);
}

class Radius {
  const Radius.circular(double radius);
}

class BorderRadius {
  const BorderRadius.all(Radius radius);
  const BorderRadius.circular(double radius);
}

class Border {
  const Border.all({Color color = const Color(0xFF000000), double width = 1.0});
}

class EdgeInsets {
  const EdgeInsets.all(double value);
  const EdgeInsets.symmetric({double vertical = 0, double horizontal = 0});
  const EdgeInsets.only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  });
}

class BoxDecoration {
  const BoxDecoration({BorderRadius? borderRadius, Border? border});
}

class Padding extends Widget {
  const Padding({super.key, required EdgeInsets padding, Widget? child});
}

class Container extends Widget {
  const Container({
    super.key,
    EdgeInsets? padding,
    BoxDecoration? decoration,
    Widget? child,
  });
}
''';
