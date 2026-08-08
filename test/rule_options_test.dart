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

/// Three distinct property accesses on one variable — the default threshold
/// for `prefer_class_destructuring`.
///
/// Deliberately pure Dart: rules needing Flutter types do not resolve under
/// `createMockSdk`, and a rule that never fires makes every "silenced"
/// assertion pass vacuously.
const _threePropertyCode = '''
class Foo {
  int get x => 1;
  int get y => 2;
  int get z => 3;
}

void f(Foo foo) {
  print(foo.x);
  print(foo.y);
  print(foo.z);
}
''';

/// Only two distinct property accesses — below the default threshold, above a
/// configured threshold of 2.
const _twoPropertyCode = '''
class Foo {
  int get x => 1;
  int get y => 2;
}

void f(Foo foo) {
  print(foo.x);
  print(foo.y);
}
''';

/// A Bloc subclass named without the default `Bloc` suffix, but *with* a
/// `Store` suffix — so it reports by default and falls silent once `suffix`
/// is reconfigured.
const _storeSuffixCode = '''
import 'package:bloc/bloc.dart';

class CounterStore extends Bloc<String, int> {}
''';

/// A private Bloc subclass lacking the suffix, for `ignore_private`.
const _privateBlocCode = '''
import 'package:bloc/bloc.dart';

class _Counter extends Bloc<String, int> {}

void f() => _Counter();
''';

/// A class reaching the tracked type through `implements`, not `extends`.
const _implementsCode = '''
import 'package:bloc/bloc.dart';

class Counter implements Repository {}
''';

/// A class reaching the tracked type through a mixin application.
const _mixinCode = '''
import 'package:bloc/bloc.dart';

class Counter with Trackable {}
''';

/// A class extending an intermediate base, so the tracked type is an
/// *indirect* ancestor.
const _indirectCode = '''
import 'package:bloc/bloc.dart';

class BaseBloc extends Bloc<String, int> {}

class Counter extends BaseBloc {}
''';

/// A locally declared type with no `package:` URI, for entries omitting
/// `package:`.
const _localTypeCode = '''
abstract class UseCase {}

class FetchUser extends UseCase {}
''';

void main() {
  group('RuleConfig.nameSetOption', () {
    Set<String> resolve(
      String yaml, {
      Set<String> defaults = const {'A', 'B'},
    }) {
      return ManyLintsConfig.parse(
        yaml,
      ).forRule('r').nameSetOption('classes', defaultValue: defaults);
    }

    test('falls back to the defaults when neither option is set', () {
      expect(resolve('rules:\n  r:\n    other: 1\n'), {'A', 'B'});
    });

    test('replaces the defaults outright', () {
      expect(resolve('rules:\n  r:\n    classes: [X]\n'), {'X'});
    });

    test('appends to the defaults', () {
      expect(resolve('rules:\n  r:\n    additional_classes: [X]\n'), {
        'A',
        'B',
        'X',
      });
    });

    test('combines replacement and addition', () {
      // `classes` picks the base list, `additional_classes` extends whichever
      // list won — so the replaced base must not reappear.
      final result = resolve(
        'rules:\n  r:\n    classes: [X]\n    additional_classes: [Y]\n',
      );
      expect(result, {'X', 'Y'});
      expect(result, isNot(contains('A')));
    });

    test('an empty replacement list means "no names", not "the defaults"', () {
      expect(resolve('rules:\n  r:\n    classes: []\n'), isEmpty);
    });

    test('a wrong-typed replacement degrades to the defaults', () {
      expect(resolve('rules:\n  r:\n    classes: "nope"\n'), {'A', 'B'});
    });

    test('non-string entries are dropped rather than crashing', () {
      expect(resolve('rules:\n  r:\n    classes: [X, 3, true]\n'), {'X'});
    });
  });

  group('options end-to-end through PluginServer', () {
    late _OptionsHarness harness;

    setUp(() async {
      ConfigLoader.clearCache();
      harness = _OptionsHarness();
      await harness.setUp();
    });

    tearDown(() async => harness.tearDown());

    group('prefer_class_destructuring min_occurrences', () {
      test('reports at the default threshold with no config', () async {
        final errors = await harness.analyze(_threePropertyCode);

        expect(
          errors.map((e) => e.code),
          contains('prefer_class_destructuring'),
        );
      });

      test('two properties are below the default threshold', () async {
        // Asymmetric baseline: proves the fixture below is genuinely silent by
        // default, so raising it to a lint is the option's doing.
        final errors = await harness.analyze(_twoPropertyCode);

        expect(
          errors.map((e) => e.code),
          isNot(contains('prefer_class_destructuring')),
        );
      });

      test('lowering the threshold reports the two-property case', () async {
        final errors = await harness.analyze(
          _twoPropertyCode,
          config: '''
rules:
  prefer_class_destructuring:
    min_occurrences: 2
''',
        );

        expect(
          errors.map((e) => e.code),
          contains('prefer_class_destructuring'),
        );
      });

      test('raising the threshold silences the three-property case', () async {
        final errors = await harness.analyze(
          _threePropertyCode,
          config: '''
rules:
  prefer_class_destructuring:
    min_occurrences: 4
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('prefer_class_destructuring')),
        );
      });

      test('a wrong-typed threshold falls back to the default', () async {
        final errors = await harness.analyze(
          _threePropertyCode,
          config: '''
rules:
  prefer_class_destructuring:
    min_occurrences: "four"
''',
        );

        // Degrades to the default (3) rather than throwing or disabling.
        expect(
          errors.map((e) => e.code),
          contains('prefer_class_destructuring'),
        );
      });

      test('the option is configurable via analysis_options too', () async {
        final errors = await harness.analyze(
          _twoPropertyCode,
          optionsSection: '''
many_lints:
  rules:
    prefer_class_destructuring:
      min_occurrences: 2
''',
        );

        expect(
          errors.map((e) => e.code),
          contains('prefer_class_destructuring'),
        );
      });
    });

    group('use_class_suffix entries', () {
      const blocSuffix = """
rules:
  use_class_suffix:
    entries:
      - type: Bloc
        package: bloc
        suffix: Bloc
""";

      test('reports nothing when unconfigured', () async {
        // The rule is entirely config-driven: installing the package must not
        // impose a naming convention.
        final errors = await harness.analyze(_storeSuffixCode, withBloc: true);

        expect(errors.map((e) => e.code), isNot(contains('use_class_suffix')));
      });

      test('reports a class violating a configured entry', () async {
        final errors = await harness.analyze(
          _storeSuffixCode,
          withBloc: true,
          config: blocSuffix,
        );

        expect(errors.map((e) => e.code), contains('use_class_suffix'));
      });

      test('accepts a class already carrying the suffix', () async {
        final errors = await harness.analyze(
          """
import 'package:bloc/bloc.dart';

class CounterBloc extends Bloc<String, int> {}
""",
          withBloc: true,
          config: blocSuffix,
        );

        expect(errors.map((e) => e.code), isNot(contains('use_class_suffix')));
      });

      test('the message names the configured suffix and class', () async {
        final errors = await harness.analyze(
          _storeSuffixCode,
          withBloc: true,
          config: blocSuffix,
        );

        final message = errors
            .firstWhere((e) => e.code == 'use_class_suffix')
            .message;
        expect(message, contains('Bloc'));
        expect(message, contains('CounterStore'));
      });

      test('a matching package pin still reports', () async {
        final errors = await harness.analyze(
          _storeSuffixCode,
          withBloc: true,
          config: blocSuffix,
        );

        expect(errors.map((e) => e.code), contains('use_class_suffix'));
      });

      test('a non-matching package pin does not match the type', () async {
        // Asymmetric to the test above: same entry, wrong package, so the
        // type must not resolve and nothing is reported.
        final errors = await harness.analyze(
          _storeSuffixCode,
          withBloc: true,
          config: """
rules:
  use_class_suffix:
    entries:
      - type: Bloc
        package: some_other_package
        suffix: Bloc
""",
        );

        expect(errors.map((e) => e.code), isNot(contains('use_class_suffix')));
      });

      test(
        'omitting package matches a type from the analyzed package',
        () async {
          // A locally declared type has no `package:` URI, so this only works
          // because a null package means "any library".
          final errors = await harness.analyze(
            _localTypeCode,
            config: """
rules:
  use_class_suffix:
    entries:
      - type: UseCase
        suffix: UseCase
""",
          );

          expect(errors.map((e) => e.code), contains('use_class_suffix'));
        },
      );

      test('never reports the configured base type itself', () async {
        // `isSuperOf` is reflexive, so without an explicit guard the base
        // type is reported for not carrying its own affix.
        final errors = await harness.analyze(
          _localTypeCode,
          config: """
rules:
  use_class_suffix:
    entries:
      - type: UseCase
        suffix: UseCase
""",
        );

        final reported = errors.where((e) => e.code == 'use_class_suffix');
        expect(reported, hasLength(1));
        expect(reported.single.message, contains('FetchUser'));
      });

      test('matches a type reached through implements', () async {
        final errors = await harness.analyze(
          _implementsCode,
          withBloc: true,
          config: """
rules:
  use_class_suffix:
    entries:
      - type: Repository
        package: bloc
        suffix: Repository
""",
        );

        expect(errors.map((e) => e.code), contains('use_class_suffix'));
      });

      test('matches a type reached through a mixin', () async {
        final errors = await harness.analyze(
          _mixinCode,
          withBloc: true,
          config: """
rules:
  use_class_suffix:
    entries:
      - type: Trackable
        package: bloc
        suffix: Trackable
""",
        );

        expect(errors.map((e) => e.code), contains('use_class_suffix'));
      });

      test('matches an indirect ancestor', () async {
        final errors = await harness.analyze(
          _indirectCode,
          withBloc: true,
          config: blocSuffix,
        );

        // Both BaseBloc (ok) and Counter (violating) derive from Bloc; only
        // Counter should be reported.
        final reported = errors.where((e) => e.code == 'use_class_suffix');
        expect(reported, hasLength(1));
      });

      test('reports a class matching two entries only once', () async {
        final errors = await harness.analyze(
          _storeSuffixCode,
          withBloc: true,
          config: """
rules:
  use_class_suffix:
    entries:
      - type: Bloc
        package: bloc
        suffix: Bloc
      - type: Bloc
        package: bloc
        suffix: Blooc
""",
        );

        expect(errors.where((e) => e.code == 'use_class_suffix'), hasLength(1));
      });

      test('reports private classes by default', () async {
        final errors = await harness.analyze(
          _privateBlocCode,
          withBloc: true,
          config: blocSuffix,
        );

        expect(errors.map((e) => e.code), contains('use_class_suffix'));
      });

      test('rule-wide ignore_private skips private classes', () async {
        final errors = await harness.analyze(
          _privateBlocCode,
          withBloc: true,
          config: """
rules:
  use_class_suffix:
    ignore_private: true
    entries:
      - type: Bloc
        package: bloc
        suffix: Bloc
""",
        );

        expect(errors.map((e) => e.code), isNot(contains('use_class_suffix')));
      });

      test(
        'rule-wide ignore_private leaves public classes reporting',
        () async {
          final errors = await harness.analyze(
            _storeSuffixCode,
            withBloc: true,
            config: """
rules:
  use_class_suffix:
    ignore_private: true
    entries:
      - type: Bloc
        package: bloc
        suffix: Bloc
""",
          );

          expect(errors.map((e) => e.code), contains('use_class_suffix'));
        },
      );

      test(
        'a per-entry ignore_private overrides the rule-wide value',
        () async {
          final errors = await harness.analyze(
            _privateBlocCode,
            withBloc: true,
            config: """
rules:
  use_class_suffix:
    ignore_private: true
    entries:
      - type: Bloc
        package: bloc
        suffix: Bloc
        ignore_private: false
""",
          );

          expect(errors.map((e) => e.code), contains('use_class_suffix'));
        },
      );

      test(
        'an entry missing its suffix is skipped, others still apply',
        () async {
          final errors = await harness.analyze(
            _storeSuffixCode,
            withBloc: true,
            config: """
rules:
  use_class_suffix:
    entries:
      - type: Cubit
        package: bloc
      - type: Bloc
        package: bloc
        suffix: Bloc
""",
          );

          expect(errors.map((e) => e.code), contains('use_class_suffix'));
        },
      );

      test('a malformed entries value degrades to no entries', () async {
        final errors = await harness.analyze(
          _storeSuffixCode,
          withBloc: true,
          config: """
rules:
  use_class_suffix:
    entries: "not a list"
""",
        );

        expect(errors.map((e) => e.code), isNot(contains('use_class_suffix')));
      });

      test('is configurable via the analysis_options section', () async {
        final errors = await harness.analyze(
          _storeSuffixCode,
          withBloc: true,
          optionsSection: """
many_lints:
  rules:
    use_class_suffix:
      entries:
        - type: Bloc
          package: bloc
          suffix: Bloc
""",
        );

        expect(errors.map((e) => e.code), contains('use_class_suffix'));
      });
    });

    group('use_class_prefix entries', () {
      const appPrefix = """
rules:
  use_class_prefix:
    entries:
      - type: Bloc
        package: bloc
        prefix: App
""";

      test('reports nothing when unconfigured', () async {
        final errors = await harness.analyze(_storeSuffixCode, withBloc: true);

        expect(errors.map((e) => e.code), isNot(contains('use_class_prefix')));
      });

      test('reports a class lacking the configured prefix', () async {
        final errors = await harness.analyze(
          _storeSuffixCode,
          withBloc: true,
          config: appPrefix,
        );

        expect(errors.map((e) => e.code), contains('use_class_prefix'));
      });

      test('accepts a class already carrying the prefix', () async {
        final errors = await harness.analyze(
          """
import 'package:bloc/bloc.dart';

class AppCounter extends Bloc<String, int> {}
""",
          withBloc: true,
          config: appPrefix,
        );

        expect(errors.map((e) => e.code), isNot(contains('use_class_prefix')));
      });

      test('a suffix entry does not drive the prefix rule', () async {
        // The two rules read different per-entry keys, so a suffix-only
        // entry must leave use_class_prefix with nothing to enforce.
        final errors = await harness.analyze(
          _storeSuffixCode,
          withBloc: true,
          config: """
rules:
  use_class_prefix:
    entries:
      - type: Bloc
        package: bloc
        suffix: Bloc
""",
        );

        expect(errors.map((e) => e.code), isNot(contains('use_class_prefix')));
      });
    });
  });
}

class _OptionsHarness with ResourceProviderMixin {
  final channel = _FakeChannel();

  late final PluginServer pluginServer;

  String get byteStoreRoot => convertPath('/byteStore');

  String get packagePath => convertPath('/package');

  String get sdkRoot => convertPath('/sdk');

  /// Writes a minimal `package:bloc` and points the package config at it.
  ///
  /// `createMockSdk` only supplies `dart:` libraries, so any rule keyed on a
  /// pub package needs the package faked or its `TypeChecker` never matches —
  /// and a rule that never fires makes every negative assertion vacuous.
  void _addBlocPackage() {
    final blocRoot = convertPath('/pkg/bloc');
    newFile(join(blocRoot, 'lib', 'bloc.dart'), '''
class Bloc<Event, State> {}
class Cubit<State> {}
abstract class Repository {}
mixin Trackable {}
''');

    newFile(join(packagePath, '.dart_tool', 'package_config.json'), '''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "package",
      "rootUri": "${toUri(packagePath)}",
      "packageUri": "lib/"
    },
    {
      "name": "bloc",
      "rootUri": "${toUri(blocRoot)}",
      "packageUri": "lib/"
    }
  ]
}
''');
  }

  Future<List<protocol.AnalysisError>> analyze(
    String content, {
    String? config,
    String? optionsSection,
    String fileName = 'test.dart',
    bool withBloc = false,
  }) async {
    final filePath = join(packagePath, 'lib', fileName);

    if (withBloc) _addBlocPackage();

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
