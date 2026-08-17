// ignore_for_file: implementation_imports
import 'dart:async';

import 'package:analysis_server_plugin/src/plugin_server.dart';
import 'package:analysis_server_plugin/src/registry.dart' as plugin_registry;
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
import 'package:many_lints/src/presets.dart';
import 'package:many_lints/src/rule_config.dart';
import 'package:test/test.dart';

/// Reported by `avoid_equal_expressions`, which is a **core** rule.
const _coreCode = '''
bool check(int a) {
  return a == a;
}
''';

/// Reported by `avoid_collapsible_if`, which is a **recommended** rule but not
/// a core one.
const _recommendedCode = '''
void main() {
  bool a = true;
  bool b = false;
  if (a) {
    if (b) {
      print('both');
    }
  }
}
''';

/// Reported by `prefer_type_over_var`, which is in the **opinionated** preset
/// only — it contradicts `omit_local_variable_types` from
/// `package:lints/recommended.yaml`, so neither `core` nor `recommended`
/// takes a side on it.
const _opinionatedCode = '''
var topLevel = 1;
''';

/// Reported by `arguments_ordering`, whose alphabetical policy is supplied by
/// the **pedantic** preset rather than by the rule's normal defaults.
const _pedanticCode = '''
void configure({int alpha = 0, int beta = 0}) {}

void main() {
  configure(beta: 2, alpha: 1);
}
''';

void main() {
  group('Preset', () {
    test('parses each known name', () {
      expect(Preset.parse('none'), Preset.none);
      expect(Preset.parse('core'), Preset.core);
      expect(Preset.parse('recommended'), Preset.recommended);
      expect(Preset.parse('opinionated'), Preset.opinionated);
      expect(Preset.parse('pedantic'), Preset.pedantic);
    });

    test('the removed `all` preset no longer resolves', () {
      expect(Preset.parse('all'), isNull);
    });

    test('returns null for an unknown name', () {
      expect(Preset.parse('reccomended'), isNull);
      expect(Preset.parse(''), isNull);
    });

    test('recommended is a strict superset of core', () {
      expect(recommendedRules, containsAll(coreRules));
      expect(recommendedRules.length, greaterThan(coreRules.length));
    });

    test('none enables nothing, opinionated enables its own tier', () {
      expect(Preset.none.enables('avoid_equal_expressions'), isFalse);
      expect(Preset.opinionated.enables('avoid_equal_expressions'), isTrue);
      expect(Preset.opinionated.enables('prefer_type_over_var'), isTrue);
    });

    test('opinionated is a strict superset of recommended', () {
      expect(opinionatedRules, containsAll(recommendedRules));
      expect(opinionatedRules.length, greaterThan(recommendedRules.length));
    });

    test('pedantic is a strict superset of opinionated', () {
      expect(pedanticRules, containsAll(opinionatedRules));
      expect(pedanticRules.length, greaterThan(opinionatedRules.length));
      expect(Preset.pedantic.enables('parameters_ordering'), isTrue);
      expect(Preset.pedantic.enables('avoid_non_null_assertion'), isTrue);
    });

    // The whole point of dropping `all`: a preset must never turn on two rules
    // whose fixes undo one another.
    test('opinionated enables neither half of a contradiction', () {
      for (final name in conflictingWithOpinionated) {
        expect(
          Preset.opinionated.enables(name),
          isFalse,
          reason: '$name contradicts a rule already in opinionated',
        );
      }
    });

    test('config-only rules stay out of every preset', () {
      // These report nothing until a project supplies its own vocabulary, so a
      // preset that enabled them would be enabling a no-op.
      for (final name in const [
        'banned_usage',
        'avoid_banned_types',
        'use_class_suffix',
      ]) {
        expect(Preset.opinionated.enables(name), isFalse, reason: name);
      }
    });

    test('core enables core rules but not recommended-only ones', () {
      expect(Preset.core.enables('avoid_equal_expressions'), isTrue);
      expect(Preset.core.enables('avoid_collapsible_if'), isFalse);
    });

    test('recommended enables both tiers but not opinionated rules', () {
      expect(Preset.recommended.enables('avoid_equal_expressions'), isTrue);
      expect(Preset.recommended.enables('avoid_collapsible_if'), isTrue);
      expect(Preset.recommended.enables('prefer_type_over_var'), isFalse);
    });

    test('bug-focused preset curation stays intentional', () {
      for (final name in const [
        'avoid_duplicate_mixins',
        'avoid_unremovable_callbacks_in_listeners',
        'function_always_returns_null',
        'function_always_returns_same_value',
        'no_equal_conditions',
        'no_equal_then_else',
        'match_getter_setter_field_names',
        'prefer_correct_test_file_name',
        'use_setstate_synchronously',
      ]) {
        expect(coreRules, isNot(contains(name)), reason: name);
        expect(recommendedRules, contains(name), reason: name);
      }

      for (final name in const [
        'avoid_catch_error',
        'avoid_future_of_either',
        'avoid_future_of_option',
        'avoid_redundant_async',
        'avoid_unnecessary_call',
        'avoid_unnecessary_constructor',
        'avoid_unnecessary_continue',
        'avoid_unnecessary_extends',
        'avoid_unnecessary_return',
        'check_for_equals_in_render_object_setters',
        'prefer_chain_either',
        'prefer_chaining_over_intermediate_run',
        'prefer_correct_json_casts',
        'prefer_do_notation',
        'prefer_from_nullable',
        'prefer_from_predicate',
        'prefer_returning_condition',
        'prefer_string_parse_extensions',
        'prefer_task_either_over_try_catch',
        'prefer_unit_over_void',
        'prefer_correct_future_return_type',
      ]) {
        expect(recommendedRules, isNot(contains(name)), reason: name);
        expect(opinionatedRules, contains(name), reason: name);
      }
    });

    test('context-dependent heuristics stay opt-in', () {
      for (final name in const [
        'avoid_duplicate_collection_elements',
        'avoid_nested_shorthands',
        'avoid_unused_after_null_check',
        'avoid_wildcard_cases_with_enums',
        'never_discard_build_context',
        'prefer_class_destructuring',
        'prefer_moving_to_variable',
      ]) {
        expect(opinionatedRules, isNot(contains(name)), reason: name);
      }

      expect(recommendedRules, isNot(contains('prefer_add_all')));
      expect(opinionatedRules, contains('prefer_add_all'));
    });

    // Guards against a preset naming a rule that was renamed or removed, which
    // would silently shrink the preset with nothing to notice it.
    test('every preset rule name is a real registered rule', () {
      // `registeredRuleNames` is filled by `register`, so the plugin has to be
      // registered against a throwaway registry before it is meaningful.
      final plugin = ManyLintsPlugin()
        ..register(plugin_registry.PluginRegistryImpl('many_lints'));
      final registered = plugin.registeredRuleNames;

      expect(registered, isNotEmpty);
      for (final name in {...pedanticRules, ...conflictingWithOpinionated}) {
        expect(
          registered,
          contains(name),
          reason: '$name is in a preset but is not a registered rule',
        );
      }
    });
  });

  group('ManyLintsConfig preset parsing', () {
    test('defaults to none when no preset is given', () {
      expect(ManyLintsConfig.parse('rules: {}').preset, Preset.none);
      expect(ManyLintsConfig.empty.preset, Preset.none);
    });

    test('reads a preset with no rules block at all', () {
      expect(ManyLintsConfig.parse('preset: core').preset, Preset.core);
    });

    test('an unknown preset name falls back rather than throwing', () {
      expect(ManyLintsConfig.parse('preset: nonsense').preset, Preset.none);
      expect(ManyLintsConfig.parse('preset: 42').preset, Preset.none);
    });

    test('reads a preset from the analysis_options section', () {
      final config = ManyLintsConfig.parseOptionsFile('''
many_lints:
  preset: recommended
''');

      expect(config.preset, Preset.recommended);
    });

    test('an explicit enabled: overrides the preset in both directions', () {
      final config = ManyLintsConfig.parse('''
preset: core
rules:
  avoid_equal_expressions:
    enabled: false
  prefer_type_over_var:
    enabled: true
''');

      // In the preset, but switched off.
      expect(config.isRuleEnabled('avoid_equal_expressions'), isFalse);
      // Not in any preset, but switched on.
      expect(config.isRuleEnabled('prefer_type_over_var'), isTrue);
      // Untouched, so the preset still decides.
      expect(config.isRuleEnabled('avoid_self_compare'), isTrue);
      expect(config.isRuleEnabled('avoid_collapsible_if'), isFalse);
    });

    test('the terse rule: bool spelling toggles a rule', () {
      final config = ManyLintsConfig.parse('''
preset: core
rules:
  prefer_type_over_var: true
  avoid_equal_expressions: false
''');

      expect(config.isRuleEnabled('prefer_type_over_var'), isTrue);
      expect(config.isRuleEnabled('avoid_equal_expressions'), isFalse);
    });

    test('a non-bool enabled: leaves the preset in charge', () {
      final config = ManyLintsConfig.parse('''
preset: core
rules:
  avoid_equal_expressions:
    enabled: "yes"
''');

      expect(config.isRuleEnabled('avoid_equal_expressions'), isTrue);
    });

    test('enabled: composes with other per-rule options', () {
      final config = ManyLintsConfig.parse('''
rules:
  avoid_only_rethrow:
    enabled: true
    exclude:
      - test/**
    ignore_typed_catches: true
''');

      expect(config.isRuleEnabled('avoid_only_rethrow'), isTrue);
      expect(config.forRule('avoid_only_rethrow').exclude, ['test/**']);
      expect(
        config
            .forRule('avoid_only_rethrow')
            .boolOption('ignore_typed_catches', defaultValue: false),
        isTrue,
      );
    });

    test(
      'pedantic supplies strict defaults that project options can replace',
      () {
        final defaults = ManyLintsConfig.parse('preset: pedantic');
        expect(
          defaults.forRule('arguments_ordering').options,
          containsPair('order', 'alphabetical'),
        );
        expect(
          defaults
              .forRule('avoid_non_null_assertion')
              .boolOption('ignore_map_indexes', defaultValue: true),
          isFalse,
        );

        final overridden = ManyLintsConfig.parse('''
preset: pedantic
rules:
  arguments_ordering:
    order: by_length
''');
        expect(
          overridden.forRule('arguments_ordering').options,
          containsPair('order', 'by_length'),
        );
      },
    );
  });

  group('end-to-end through PluginServer', () {
    late _PresetHarness harness;

    setUp(() async {
      ConfigLoader.clearCache();
      harness = _PresetHarness();
      await harness.setUp();
    });

    tearDown(() async => harness.tearDown());

    test('reports nothing when no configuration exists', () async {
      final errors = await harness.analyze(_coreCode);

      expect(
        errors.map((e) => e.code),
        isNot(contains('avoid_equal_expressions')),
      );
    });

    test('preset: core enables a core rule', () async {
      final errors = await harness.analyze(_coreCode, config: 'preset: core');

      expect(errors.map((e) => e.code), contains('avoid_equal_expressions'));
    });

    test('preset: core leaves a recommended-only rule off', () async {
      final errors = await harness.analyze(
        _recommendedCode,
        config: 'preset: core',
      );

      expect(
        errors.map((e) => e.code),
        isNot(contains('avoid_collapsible_if')),
      );
    });

    test('preset: recommended enables both tiers', () async {
      final coreErrors = await harness.analyze(
        _coreCode,
        config: 'preset: recommended',
      );
      expect(
        coreErrors.map((e) => e.code),
        contains('avoid_equal_expressions'),
      );
    });

    test('preset: recommended enables a recommended-only rule', () async {
      final errors = await harness.analyze(
        _recommendedCode,
        config: 'preset: recommended',
      );

      expect(errors.map((e) => e.code), contains('avoid_collapsible_if'));
    });

    test('preset: recommended leaves an opinionated rule off', () async {
      final errors = await harness.analyze(
        _opinionatedCode,
        config: 'preset: recommended',
      );

      expect(
        errors.map((e) => e.code),
        isNot(contains('prefer_type_over_var')),
      );
    });

    test('preset: opinionated enables an opinionated rule', () async {
      final errors = await harness.analyze(
        _opinionatedCode,
        config: 'preset: opinionated',
      );

      expect(errors.map((e) => e.code), contains('prefer_type_over_var'));
    });

    test('preset: pedantic enables and configures a pedantic rule', () async {
      final errors = await harness.analyze(
        _pedanticCode,
        config: 'preset: pedantic',
      );

      expect(errors.map((e) => e.code), contains('arguments_ordering'));
    });

    test('an unknown preset silently enables nothing', () async {
      // `all` was removed in 1.0.0. Config problems cannot be reported as
      // diagnostics, so a stale name degrades to `none` rather than throwing —
      // which is exactly why the docs have to stop advertising it.
      final errors = await harness.analyze(
        _opinionatedCode,
        config: 'preset: all',
      );

      expect(
        errors.map((e) => e.code),
        isNot(contains('prefer_type_over_var')),
      );
    });

    test('a rule can be added on top of a preset', () async {
      final errors = await harness.analyze(
        _opinionatedCode,
        config: '''
preset: core
rules:
  prefer_type_over_var:
    enabled: true
''',
      );

      expect(errors.map((e) => e.code), contains('prefer_type_over_var'));
    });

    test('a rule can be removed from a preset', () async {
      final errors = await harness.analyze(
        _coreCode,
        config: '''
preset: core
rules:
  avoid_equal_expressions:
    enabled: false
''',
      );

      expect(
        errors.map((e) => e.code),
        isNot(contains('avoid_equal_expressions')),
      );
    });

    test('a rule enabled without any preset reports', () async {
      final errors = await harness.analyze(
        _coreCode,
        config: '''
rules:
  avoid_equal_expressions:
    enabled: true
''',
      );

      expect(errors.map((e) => e.code), contains('avoid_equal_expressions'));
    });

    test('exclude still applies to a rule a preset enabled', () async {
      final errors = await harness.analyze(
        _coreCode,
        fileName: 'legacy.dart',
        config: '''
preset: core
rules:
  avoid_equal_expressions:
    exclude:
      - lib/legacy.dart
''',
      );

      expect(
        errors.map((e) => e.code),
        isNot(contains('avoid_equal_expressions')),
      );
    });

    test('a preset can be selected from analysis_options.yaml', () async {
      final errors = await harness.analyze(
        _coreCode,
        optionsSection: '''
many_lints:
  preset: core
''',
      );

      expect(errors.map((e) => e.code), contains('avoid_equal_expressions'));
    });
  });
}

class _PresetHarness with ResourceProviderMixin {
  final channel = _FakeChannel();

  late final PluginServer pluginServer;

  String get byteStoreRoot => convertPath('/byteStore');

  String get packagePath => convertPath('/package');

  String get sdkRoot => convertPath('/sdk');

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

    final id = '${_idCounter++}';
    final completer = Completer<protocol.Response>();
    _completers[id] = completer;
    onRequest(params.toRequest(id));
    return completer.future;
  }

  @override
  void sendResponse(protocol.Response response) {
    _completers.remove(response.id)?.complete(response);
  }
}
