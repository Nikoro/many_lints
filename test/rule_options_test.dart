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

/// An enum interpolated into a string. Exempt by default (it renders as
/// `Status.active`), reported under `report_enums: true`.
const _interpolatedEnumCode = '''
enum Status { active, inactive }

String describe(Status status) => 'status: \$status';
''';

/// A local read before an await and written back after it. Exempt by default
/// (only fields are shared), reported under `include_local_variables: true`.
const _staleLocalCode = '''
Future<void> run() async {
  var total = 0;
  final current = total;
  await Future<void>.delayed(Duration.zero);
  total = current + 1;
}
''';

/// The same shape on a field, which is reported regardless of the option — the
/// control proving `include_local_variables` widens rather than replaces.
const _staleFieldCode = '''
class Counter {
  int value = 0;

  Future<void> increment() async {
    final current = value;
    await Future<void>.delayed(Duration.zero);
    value = current + 1;
  }
}
''';

/// A Cubit emitting the current state through `emit`, which is reported with
/// no configuration at all.
const _emitStateCode = '''
import 'package:bloc/bloc.dart';

class CounterCubit extends Cubit<int> {
  void refresh() {
    emit(state);
  }
}
''';

/// The same no-op through a project wrapper, which only `additional_methods`
/// can reach.
const _safeEmitStateCode = '''
import 'package:bloc/bloc.dart';

class CounterCubit extends Cubit<int> {
  void refresh() {
    safeEmit(state);
  }
}
''';

/// An async closure passed to a `void`-returning parameter named `onPressed`,
/// so both `ignored_parameters` and `ignore_widget_callbacks` can reach it.
const _asyncVoidCallbackCode = '''
void build({required void Function() onPressed}) {}

Future<void> save() async {}

void f() {
  build(onPressed: () async {
    await save();
  });
}
''';

/// The same shape on a plainly named parameter, which neither option targets —
/// the asymmetric control proving they narrow rather than disable.
const _asyncVoidPlainCode = '''
void schedule(void Function() task) {}

Future<void> save() async {}

void f() {
  schedule(() async {
    await save();
  });
}
''';

/// An `is` check between unrelated core types, which `report_is_checks: false`
/// silences.
const _unrelatedIsCheckCode = '''
bool f(String value) => value is int;
''';

/// The `as` form of the same mismatch, which stays reported either way — the
/// asymmetric control for `report_is_checks`.
const _unrelatedAsCastCode = '''
int f(String value) => value as int;
''';

/// A `toJson` map holding a type the project converts elsewhere, reachable
/// only via `allowed_types`.
const _customEncodableCode = '''
class Decimal {}

class Price {
  Price(this.amount);

  final Decimal amount;

  Map<String, dynamic> toJson() => {'amount': amount};
}
''';

/// A `toJson` map holding a plainly non-encodable type, which stays reported
/// even with an unrelated `allowed_types` entry.
const _plainNotEncodableCode = '''
class Other {}

class Price {
  Price(this.other);

  final Other other;

  Map<String, dynamic> toJson() => {'other': other};
}
''';

/// An enum that *does* override toString, which stays exempt even under
/// `report_enums` — the asymmetric half of that option's tests.
const _enumWithToStringCode = '''
enum Status {
  active,
  inactive;

  @override
  String toString() => 'Status(\$name)';
}

String describe(Status status) => 'status: \$status';
''';

/// Two labels sharing one body. Convertible only as `case 'a' || 'b' =>`,
/// so it is reported only under `allow_fallthrough_cases: true`.
const _fallthroughSwitchCode = '''
int score(String grade) {
  switch (grade) {
    case 'a':
    case 'b':
      return 1;
    default:
      return 0;
  }
}
''';

/// A fallthrough case with nothing after it to share a body with, so there is
/// no pattern to merge into — unreported even with the option on.
const _trailingFallthroughCode = '''
int score(String grade) {
  switch (grade) {
    default:
      return 0;
    case 'a':
  }
}
''';

/// A `dynamic` argument passed to `contains` on a typed list. Skipped by
/// default because the real type is unknown; reported under `strict: true`.
const _dynamicContainsCode = '''
bool check(List<int> values, dynamic candidate) => values.contains(candidate);
''';

const _completerOutsideCatchCode = '''
import 'dart:async';

void fail(Completer<void> completer, Object error) {
  completer.completeError(error);
}
''';

const _renamedPrivateParameterCode = '''
class Bird {
  final String _petName;
  Bird({required String name}) : _petName = name;
}
''';

const _customStateNameCode = '''
class LoadingStatus {}
''';

/// A field below a method: reported by the default order, and by any order
/// listing fields before methods.
const _memberOrderCode = '''
class Order {
  void submit() {}
  final int id = 0;
}
''';

const _ignoredStreamCode = '''
void subscribe(Stream<int> serviceStream) {
  serviceStream.listen(print);
}
''';

const _customListenerCode = '''
class Source {
  void watch(void Function() callback) {}
}

void subscribe(Source source) {
  source.watch(() {});
}
''';

const _customShorthandCode = '''
class Insets {
  const Insets.named();
}

void consume(Insets value) {}
void use() => consume(Insets.named());
''';

const _defaultShorthandCode = '''
class EdgeInsets {
  const EdgeInsets.all(double value);
}

void consume(EdgeInsets value) {}
void use() => consume(EdgeInsets.all(8));
''';

const _enumContainsCode = '''
enum Status { loading, ready, failed }

bool isBusy(Status status) =>
    {Status.loading, Status.ready, Status.failed}.contains(status);
''';

const _safeEmitAfterAwaitCode = '''
import 'package:bloc/bloc.dart';

class CounterCubit extends Cubit<int> {
  Future<void> load() async {
    await Future<void>.delayed(Duration.zero);
    safeEmit(1);
  }
}
''';

const _duplicateCustomHandlerCode = '''
import 'package:bloc/bloc.dart';

class Event {}

class CounterBloc extends Bloc<Event, int> {
  CounterBloc() {
    handle<Event>((event, emit) {});
    handle<Event>((event, emit) {});
  }
}
''';

const _hookInCustomBuildMethodCode = '''
import 'package:flutter_hooks/flutter_hooks.dart';

class MyWidget extends HookWidget {
  Widget buildBody() {
    useState(0);
    return const Widget();
  }
}
''';

const _misusedHookCode = '''
import 'package:flutter_hooks/flutter_hooks.dart';

class MyWidget extends HookWidget {
  Widget build(BuildContext context) {
    for (var i = 0; i < 2; i++) {
      useState(i);
    }
    return const Widget();
  }
}
''';

const _widgetReturningHelpersCode = '''
import 'package:flutter/widgets.dart';

const generated = Object();

Widget buildHelper() => const Widget();

@generated
Widget generatedHelper() => const Widget();

Widget? maybeBuild() => null;
''';

const _customRenderDirtyCode = '''
import 'package:flutter/widgets.dart';

class MyRenderObject extends RenderObject {
  int _value = 0;
  void invalidate() {}

  set value(int value) {
    _value = value;
    invalidate();
  }
}
''';

const _privateSecondWidgetCode = '''
import 'package:flutter/widgets.dart';

class PublicWidget extends Widget {}
class _PrivateWidget extends Widget {}
''';

const _visibleForTestingWidgetCode = '''
import 'package:flutter/widgets.dart';

class PublicWidget extends Widget {}
@visibleForTesting
class TestWidget extends Widget {}
''';

/// Two public classes and an enum — pure Dart, so the default group of
/// `prefer_single_declaration_per_file` fires without any package mocking.
const _twoDeclarationsCode = '''
class First {}
class Second {}
enum Third { one }
''';

/// One class per "group" once `groups:` narrows by base type: a file holding
/// one of each is the layout a grouped configuration asks for.
///
/// The base types are declared in a separate part-free library on purpose.
/// `TypeChecker.isSuperOf` is reflexive, so declaring `Store` beside
/// `CounterStore` would put two members in the `Store` group and report — the
/// same gotcha the config cookbook documents for `use_class_suffix`.
const _oneOfEachBaseCode = '''
import 'bases.dart';

class CounterStore extends Store {}
class CounterController extends Controller {}
''';

/// The base types [_oneOfEachBaseCode] extends, kept in their own library.
const _baseTypesCode = '''
abstract class Store {}
abstract class Controller {}
''';

const _spacingChildrenCode = '''
import 'package:flutter/widgets.dart';

Widget build() => Column(children: const [
  Widget(),
  SizedBox(height: 8),
  Widget(),
]);
''';

const _gapChildrenCode = '''
import 'package:flutter/widgets.dart';

Widget build() => Column(children: const [
  SizedBox(height: 8),
  Widget(),
]);
''';

const _twoContainerWidgetsCode = '''
import 'package:flutter/widgets.dart';

Widget build() => Padding(child: Align(child: const Widget()));
''';

/// A state-like class that does **not** extend Flutter's `State`, holding a
/// disposable field that is never disposed.
///
/// `dispose_fields` skips it entirely by default, which is exactly the gap
/// `state_base_classes` exists to close. Pure Dart, so it resolves under
/// `createMockSdk` — a Flutter-typed fixture would report nothing and make
/// every assertion here pass vacuously.
const _customStateBaseCode = '''
class DisposableController {
  void dispose() {}
}

class Ticker {
  void dispose() {}
}

class MyController extends DisposableController {
  final Ticker ticker = Ticker();
}
''';

/// A single commented-out line — the smallest block `avoid_commented_out_code`
/// reports by default.
const _oneLineCommentedCode = '''
void main() {
  // print('hello');
}
''';

/// Two consecutive commented-out lines, which stay reported at `min_lines: 2`.
const _twoLineCommentedCode = '''
void main() {
  // print('hello');
  // print('world');
}
''';

/// A list literal repeating the same literal value.
const _duplicateLiteralCode = '''
final values = [1, 2, 1];
''';

/// A list literal repeating the same identifier, which `ignore_literals` must
/// still report — the asymmetric half of that option's tests.
const _duplicateIdentifierCode = '''
const a = 1;
const b = 2;
final values = [a, b, a];
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

    // Options that make a rule report *more* than it does by default. Each
    // pair proves the default is unchanged and the option genuinely widens.
    group('widening options', () {
      group('avoid_default_tostring report_enums', () {
        test('an interpolated enum is exempt by default', () async {
          final errors = await harness.analyze(_interpolatedEnumCode);

          expect(
            errors.map((e) => e.code),
            isNot(contains('avoid_default_tostring')),
          );
        });

        test('report_enums reports it', () async {
          final errors = await harness.analyze(
            _interpolatedEnumCode,
            config: '''
rules:
  avoid_default_tostring:
    report_enums: true
''',
          );

          expect(errors.map((e) => e.code), contains('avoid_default_tostring'));
        });

        test('report_enums leaves an enum with toString alone', () async {
          final errors = await harness.analyze(
            _enumWithToStringCode,
            config: '''
rules:
  avoid_default_tostring:
    report_enums: true
''',
          );

          expect(
            errors.map((e) => e.code),
            isNot(contains('avoid_default_tostring')),
          );
        });
      });

      group('emit_new_bloc_state_instances additional_methods', () {
        test('emit(state) is reported with no config', () async {
          final errors = await harness.analyze(_emitStateCode, withBloc: true);

          expect(
            errors.map((e) => e.code),
            contains('emit_new_bloc_state_instances'),
          );
        });

        test('a project wrapper is not reached by default', () async {
          final errors = await harness.analyze(
            _safeEmitStateCode,
            withBloc: true,
          );

          expect(
            errors.map((e) => e.code),
            isNot(contains('emit_new_bloc_state_instances')),
          );
        });

        test('additional_methods reaches the wrapper', () async {
          final errors = await harness.analyze(
            _safeEmitStateCode,
            withBloc: true,
            config: '''
rules:
  emit_new_bloc_state_instances:
    additional_methods: [safeEmit]
''',
          );

          expect(
            errors.map((e) => e.code),
            contains('emit_new_bloc_state_instances'),
          );
        });

        test('additional_methods still leaves emit reporting', () async {
          final errors = await harness.analyze(
            _emitStateCode,
            withBloc: true,
            config: '''
rules:
  emit_new_bloc_state_instances:
    additional_methods: [safeEmit]
''',
          );

          expect(
            errors.map((e) => e.code),
            contains('emit_new_bloc_state_instances'),
          );
        });
      });

      group('require_atomic_async_updates include_local_variables', () {
        test('a field is reported with no config', () async {
          final errors = await harness.analyze(_staleFieldCode);

          expect(
            errors.map((e) => e.code),
            contains('require_atomic_async_updates'),
          );
        });

        test('a local is exempt by default', () async {
          final errors = await harness.analyze(_staleLocalCode);

          expect(
            errors.map((e) => e.code),
            isNot(contains('require_atomic_async_updates')),
          );
        });

        test('include_local_variables reports it', () async {
          final errors = await harness.analyze(
            _staleLocalCode,
            config: '''
rules:
  require_atomic_async_updates:
    include_local_variables: true
''',
          );

          expect(
            errors.map((e) => e.code),
            contains('require_atomic_async_updates'),
          );
        });

        test('a wrong-typed value falls back to the default', () async {
          final errors = await harness.analyze(
            _staleLocalCode,
            config: '''
rules:
  require_atomic_async_updates:
    include_local_variables: "yes"
''',
          );

          expect(
            errors.map((e) => e.code),
            isNot(contains('require_atomic_async_updates')),
          );
        });
      });

      group('prefer_switch_expression allow_fallthrough_cases', () {
        test('a fallthrough switch is not reported by default', () async {
          final errors = await harness.analyze(_fallthroughSwitchCode);

          expect(
            errors.map((e) => e.code),
            isNot(contains('prefer_switch_expression')),
          );
        });

        test('the option reports it', () async {
          final errors = await harness.analyze(
            _fallthroughSwitchCode,
            config: '''
rules:
  prefer_switch_expression:
    allow_fallthrough_cases: true
''',
          );

          expect(
            errors.map((e) => e.code),
            contains('prefer_switch_expression'),
          );
        });

        test('a trailing fallthrough stays unreported', () async {
          // Nothing to merge the dangling pattern into, so neither the rule
          // nor the fix can act.
          final errors = await harness.analyze(
            _trailingFallthroughCode,
            config: '''
rules:
  prefer_switch_expression:
    allow_fallthrough_cases: true
''',
          );

          expect(
            errors.map((e) => e.code),
            isNot(contains('prefer_switch_expression')),
          );
        });
      });

      group('avoid_collection_methods_with_unrelated_types strict', () {
        test('a dynamic argument is not reported by default', () async {
          final errors = await harness.analyze(_dynamicContainsCode);

          expect(
            errors.map((e) => e.code),
            isNot(contains('avoid_collection_methods_with_unrelated_types')),
          );
        });

        test('strict reports it', () async {
          final errors = await harness.analyze(
            _dynamicContainsCode,
            config: '''
rules:
  avoid_collection_methods_with_unrelated_types:
    strict: true
''',
          );

          expect(
            errors.map((e) => e.code),
            contains('avoid_collection_methods_with_unrelated_types'),
          );
        });
      });

      group('avoid_missing_completer_stack_trace require_inside_catch', () {
        test('false reports calls outside catch blocks', () async {
          final errors = await harness.analyze(
            _completerOutsideCatchCode,
            config: '''
rules:
  avoid_missing_completer_stack_trace:
    require_inside_catch: false
''',
          );

          expect(
            errors.map((e) => e.code),
            contains('avoid_missing_completer_stack_trace'),
          );
        });
      });

      group('check_is_not_closed_after_async_gap additional_methods', () {
        test('reports a configured emit wrapper', () async {
          final errors = await harness.analyze(
            _safeEmitAfterAwaitCode,
            withBloc: true,
            config: '''
rules:
  check_is_not_closed_after_async_gap:
    additional_methods: [safeEmit]
''',
          );

          expect(
            errors.map((e) => e.code),
            contains('check_is_not_closed_after_async_gap'),
          );
        });
      });

      group('avoid_duplicate_bloc_event_handlers additional_methods', () {
        test('reports duplicate registrations through a wrapper', () async {
          final errors = await harness.analyze(
            _duplicateCustomHandlerCode,
            withBloc: true,
            config: '''
rules:
  avoid_duplicate_bloc_event_handlers:
    additional_methods: [handle]
''',
          );

          expect(
            errors.map((e) => e.code),
            contains('avoid_duplicate_bloc_event_handlers'),
          );
        });
      });

      // `name_pattern` moved to `prefer_immutable_state` in 0.10.0, when the
      // name-based half was split out of the Bloc rule.
      group('member_ordering order', () {
        test('reports a member out of the configured order', () async {
          final errors = await harness.analyze(
            _memberOrderCode,
            config: '''
rules:
  member_ordering:
    order:
      - public_fields
      - public_methods
''',
          );

          expect(errors.map((e) => e.code), contains('member_ordering'));
        });

        test('an order that omits fields does not rank them', () async {
          // The asymmetric counterpart: with fields left out of the order,
          // the same file must be silent — proving the option is read rather
          // than the rule simply never firing.
          final errors = await harness.analyze(
            _memberOrderCode,
            config: '''
rules:
  member_ordering:
    order:
      - public_methods
      - private_methods
''',
          );

          expect(errors.map((e) => e.code), isNot(contains('member_ordering')));
        });
      });

      group('prefer_immutable_state name_pattern', () {
        test('reports a class matching the configured pattern', () async {
          final errors = await harness.analyze(
            _customStateNameCode,
            config: '''
rules:
  prefer_immutable_state:
    name_pattern: 'Status\$'
''',
          );

          expect(errors.map((e) => e.code), contains('prefer_immutable_state'));
        });

        test('leaves the class alone under the default pattern', () async {
          // The asymmetric counterpart: silence alone cannot distinguish "the
          // option worked" from "the rule never fired".
          final errors = await harness.analyze(
            _customStateNameCode,
            config: '''
rules:
  prefer_immutable_state:
    enabled: true
''',
          );

          expect(
            errors.map((e) => e.code),
            isNot(contains('prefer_immutable_state')),
          );
        });
      });

      group('prefer_private_named_parameters only_same_name', () {
        test('false reports renamed constructor parameters', () async {
          final errors = await harness.analyze(
            _renamedPrivateParameterCode,
            config: '''
rules:
  prefer_private_named_parameters:
    only_same_name: false
''',
          );

          expect(
            errors.map((e) => e.code),
            contains('prefer_private_named_parameters'),
          );
        });
      });
    });

    group('prefer_switch_with_enums ignore_contains', () {
      test('silences enum membership tests', () async {
        final errors = await harness.analyze(
          _enumContainsCode,
          config: '''
rules:
  prefer_switch_with_enums:
    ignore_contains: true
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('prefer_switch_with_enums')),
        );
      });
    });

    group('avoid_unassigned_stream_subscriptions ignored_instances', () {
      test('silences a configured receiver', () async {
        final errors = await harness.analyze(
          _ignoredStreamCode,
          config: '''
rules:
  avoid_unassigned_stream_subscriptions:
    ignored_instances: [serviceStream]
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('avoid_unassigned_stream_subscriptions')),
        );
      });
    });

    group('avoid_unremovable_callbacks_in_listeners additional_methods', () {
      test(
        'reports an inline callback passed to a configured method',
        () async {
          final errors = await harness.analyze(
            _customListenerCode,
            config: '''
rules:
  avoid_unremovable_callbacks_in_listeners:
    additional_methods: [watch]
''',
          );

          expect(
            errors.map((e) => e.code),
            contains('avoid_unremovable_callbacks_in_listeners'),
          );
        },
      );
    });

    group('prefer_shorthands_with_constructors class lists', () {
      test('classes replaces the defaults', () async {
        final errors = await harness.analyze(
          _customShorthandCode,
          config: '''
rules:
  prefer_shorthands_with_constructors:
    classes: [Insets]
''',
        );

        expect(
          errors.map((e) => e.code),
          contains('prefer_shorthands_with_constructors'),
        );
      });

      test('an empty classes list disables the defaults', () async {
        final errors = await harness.analyze(
          _defaultShorthandCode,
          config: '''
rules:
  prefer_shorthands_with_constructors:
    classes: []
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('prefer_shorthands_with_constructors')),
        );
      });

      test('additional_classes extends the defaults', () async {
        final errors = await harness.analyze(
          _customShorthandCode,
          config: '''
rules:
  prefer_shorthands_with_constructors:
    additional_classes: [Insets]
''',
        );

        expect(
          errors.map((e) => e.code),
          contains('prefer_shorthands_with_constructors'),
        );
      });
    });

    group('avoid_hooks_outside_build additional_methods', () {
      test('allows hooks in a configured HookWidget method', () async {
        final errors = await harness.analyze(
          _hookInCustomBuildMethodCode,
          withHooks: true,
          config: '''
rules:
  avoid_hooks_outside_build:
    additional_methods: [buildBody]
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('avoid_hooks_outside_build')),
        );
      });
    });

    group('avoid_misused_hooks exemptions', () {
      test('ignored_names exempts a configured hook', () async {
        final errors = await harness.analyze(
          _misusedHookCode,
          withHooks: true,
          config: '''
rules:
  avoid_misused_hooks:
    ignored_names: [useState]
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('avoid_misused_hooks')),
        );
      });

      test('ignored_widgets exempts a configured widget', () async {
        final errors = await harness.analyze(
          _misusedHookCode,
          withHooks: true,
          config: '''
rules:
  avoid_misused_hooks:
    ignored_widgets: [MyWidget]
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('avoid_misused_hooks')),
        );
      });
    });

    group('avoid_returning_widgets exemptions', () {
      test('ignored_names exempts a configured helper', () async {
        final errors = await harness.analyze(
          _widgetReturningHelpersCode,
          withFlutter: true,
          config: '''
rules:
  avoid_returning_widgets:
    ignored_names: [buildHelper]
''',
        );

        final diagnostics = errors
            .where((e) => e.code == 'avoid_returning_widgets')
            .toList();
        expect(diagnostics, hasLength(2));
      });

      test('ignored_annotations exempts an annotated helper', () async {
        final errors = await harness.analyze(
          _widgetReturningHelpersCode,
          withFlutter: true,
          config: '''
rules:
  avoid_returning_widgets:
    ignored_annotations: [generated]
''',
        );

        final diagnostics = errors
            .where((e) => e.code == 'avoid_returning_widgets')
            .toList();
        expect(diagnostics, hasLength(2));
      });

      test('allow_nullable exempts nullable widget returns', () async {
        final errors = await harness.analyze(
          _widgetReturningHelpersCode,
          withFlutter: true,
          config: '''
rules:
  avoid_returning_widgets:
    allow_nullable: true
''',
        );

        final diagnostics = errors
            .where((e) => e.code == 'avoid_returning_widgets')
            .toList();
        expect(diagnostics, hasLength(2));
      });
    });

    group('check_for_equals_in_render_object_setters additional_methods', () {
      test('recognizes a configured dirty-marking method', () async {
        final errors = await harness.analyze(
          _customRenderDirtyCode,
          withFlutter: true,
          config: '''
rules:
  check_for_equals_in_render_object_setters:
    additional_methods: [invalidate]
''',
        );

        expect(
          errors.map((e) => e.code),
          contains('check_for_equals_in_render_object_setters'),
        );
      });
    });

    group('prefer_single_declaration_per_file groups', () {
      // Control: without this, every "silenced" assertion below could pass
      // because the rule never ran at all.
      test('reports the second declaration when merely enabled', () async {
        final errors = await harness.analyze(
          _twoDeclarationsCode,
          config: '''
rules:
  prefer_single_declaration_per_file: true
''',
        );

        expect(
          errors.map((e) => e.code),
          contains('prefer_single_declaration_per_file'),
        );
      });

      test('kinds narrows which declarations count', () async {
        final errors = await harness.analyze(
          '''
class First {}
enum Second { one }
''',
          config: '''
rules:
  prefer_single_declaration_per_file:
    kinds: [class]
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('prefer_single_declaration_per_file')),
        );
      });

      // Asymmetric partner to the test above: the same option still reports
      // when the file holds two declarations of the configured kind.
      test('kinds still reports two of the configured kind', () async {
        final errors = await harness.analyze(
          _twoDeclarationsCode,
          config: '''
rules:
  prefer_single_declaration_per_file:
    kinds: [class]
''',
        );

        expect(
          errors.map((e) => e.code),
          contains('prefer_single_declaration_per_file'),
        );
      });

      test('groups give each type its own budget', () async {
        harness.addLibrary('bases.dart', _baseTypesCode);

        final errors = await harness.analyze(
          _oneOfEachBaseCode,
          config: '''
rules:
  prefer_single_declaration_per_file:
    groups:
      - types: [Store]
      - types: [Controller]
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('prefer_single_declaration_per_file')),
        );
      });

      // Asymmetric partner: one group covering both base types collapses the
      // budgets, so the same file now reports.
      test('a single group covering both types reports', () async {
        harness.addLibrary('bases.dart', _baseTypesCode);

        final errors = await harness.analyze(
          _oneOfEachBaseCode,
          config: '''
rules:
  prefer_single_declaration_per_file:
    groups:
      - types: [Store, Controller]
''',
        );

        expect(
          errors.map((e) => e.code),
          contains('prefer_single_declaration_per_file'),
        );
      });

      test("a group's message is appended to its diagnostics", () async {
        final errors = await harness.analyze(
          _twoDeclarationsCode,
          config: '''
rules:
  prefer_single_declaration_per_file:
    groups:
      - kinds: [class]
        message: 'One class per file, please.'
''',
        );

        final message = errors
            .firstWhere((e) => e.code == 'prefer_single_declaration_per_file')
            .message;

        expect(message, contains('One class per file, please.'));
      });
    });

    group('prefer_single_widget_per_file exemptions', () {
      test('ignore_private_widgets false includes private widgets', () async {
        final errors = await harness.analyze(
          _privateSecondWidgetCode,
          withFlutter: true,
          config: '''
rules:
  prefer_single_widget_per_file:
    ignore_private_widgets: false
''',
        );

        expect(
          errors.map((e) => e.code),
          contains('prefer_single_widget_per_file'),
        );
      });

      test('ignore_visible_for_testing exempts annotated widgets', () async {
        final errors = await harness.analyze(
          _visibleForTestingWidgetCode,
          withFlutter: true,
          config: '''
rules:
  prefer_single_widget_per_file:
    ignore_visible_for_testing: true
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('prefer_single_widget_per_file')),
        );
      });
    });

    group('widget sequence thresholds', () {
      test('prefer_spacing min_children raises the threshold', () async {
        final errors = await harness.analyze(
          _spacingChildrenCode,
          withFlutter: true,
          config: '''
rules:
  prefer_spacing:
    min_children: 4
''',
        );

        expect(errors.map((e) => e.code), isNot(contains('prefer_spacing')));
      });

      test('use_gap min_children raises the threshold', () async {
        final errors = await harness.analyze(
          _gapChildrenCode,
          withFlutter: true,
          config: '''
rules:
  use_gap:
    min_children: 3
''',
        );

        expect(errors.map((e) => e.code), isNot(contains('use_gap')));
      });

      test('prefer_container min_sequence lowers the threshold', () async {
        final errors = await harness.analyze(
          _twoContainerWidgetsCode,
          withFlutter: true,
          config: '''
rules:
  prefer_container:
    min_sequence: 2
''',
        );

        expect(errors.map((e) => e.code), contains('prefer_container'));
      });
    });

    group('avoid_not_encodable_in_to_json allowed_types', () {
      test('a non-encodable type is reported with no config', () async {
        final errors = await harness.analyze(_customEncodableCode);

        expect(
          errors.map((e) => e.code),
          contains('avoid_not_encodable_in_to_json'),
        );
      });

      test('allowed_types silences the named type', () async {
        final errors = await harness.analyze(
          _customEncodableCode,
          config: '''
rules:
  avoid_not_encodable_in_to_json:
    allowed_types: [Decimal]
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('avoid_not_encodable_in_to_json')),
        );
      });

      test('allowed_types leaves other types reporting', () async {
        final errors = await harness.analyze(
          _plainNotEncodableCode,
          config: '''
rules:
  avoid_not_encodable_in_to_json:
    allowed_types: [Decimal]
''',
        );

        expect(
          errors.map((e) => e.code),
          contains('avoid_not_encodable_in_to_json'),
        );
      });
    });

    group('avoid_unrelated_type_casts report_is_checks', () {
      test('an unrelated is check is reported by default', () async {
        final errors = await harness.analyze(_unrelatedIsCheckCode);

        expect(
          errors.map((e) => e.code),
          contains('avoid_unrelated_type_casts'),
        );
      });

      test('report_is_checks: false silences it', () async {
        final errors = await harness.analyze(
          _unrelatedIsCheckCode,
          config: '''
rules:
  avoid_unrelated_type_casts:
    report_is_checks: false
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('avoid_unrelated_type_casts')),
        );
      });

      test('report_is_checks: false leaves as casts reporting', () async {
        final errors = await harness.analyze(
          _unrelatedAsCastCode,
          config: '''
rules:
  avoid_unrelated_type_casts:
    report_is_checks: false
''',
        );

        expect(
          errors.map((e) => e.code),
          contains('avoid_unrelated_type_casts'),
        );
      });
    });

    group('avoid_passing_async_when_sync_expected exemptions', () {
      test('an async void callback is reported with no config', () async {
        final errors = await harness.analyze(_asyncVoidCallbackCode);

        expect(
          errors.map((e) => e.code),
          contains('avoid_passing_async_when_sync_expected'),
        );
      });

      test('ignored_parameters silences the named parameter', () async {
        final errors = await harness.analyze(
          _asyncVoidCallbackCode,
          config: '''
rules:
  avoid_passing_async_when_sync_expected:
    ignored_parameters: [onPressed]
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('avoid_passing_async_when_sync_expected')),
        );
      });

      test('ignored_parameters leaves other parameters reporting', () async {
        final errors = await harness.analyze(
          _asyncVoidPlainCode,
          config: '''
rules:
  avoid_passing_async_when_sync_expected:
    ignored_parameters: [onPressed]
''',
        );

        expect(
          errors.map((e) => e.code),
          contains('avoid_passing_async_when_sync_expected'),
        );
      });

      test('ignore_widget_callbacks silences onPressed', () async {
        final errors = await harness.analyze(
          _asyncVoidCallbackCode,
          config: '''
rules:
  avoid_passing_async_when_sync_expected:
    ignore_widget_callbacks: true
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('avoid_passing_async_when_sync_expected')),
        );
      });

      test(
        'ignore_widget_callbacks leaves a plain parameter reporting',
        () async {
          final errors = await harness.analyze(
            _asyncVoidPlainCode,
            config: '''
rules:
  avoid_passing_async_when_sync_expected:
    ignore_widget_callbacks: true
''',
          );

          expect(
            errors.map((e) => e.code),
            contains('avoid_passing_async_when_sync_expected'),
          );
        },
      );
    });

    group('state_base_classes', () {
      // `dispose_fields` normally only looks inside a Flutter `State`
      // subclass. A state-like base that does not extend `State` is invisible
      // to it — that is the gap this option closes, not the intermediate
      // `BaseState<T>` case, which `isSuperOf` already walks to.
      test('a non-State base is ignored by default', () async {
        final errors = await harness.analyze(_customStateBaseCode);

        expect(errors.map((e) => e.code), isNot(contains('dispose_fields')));
      });

      test('configuring the base makes the rule apply', () async {
        final errors = await harness.analyze(
          _customStateBaseCode,
          config: '''
rules:
  dispose_fields:
    state_base_classes: [DisposableController]
''',
        );

        expect(errors.map((e) => e.code), contains('dispose_fields'));
      });

      test('an unrelated configured name changes nothing', () async {
        final errors = await harness.analyze(
          _customStateBaseCode,
          config: '''
rules:
  dispose_fields:
    state_base_classes: [SomethingElse]
''',
        );

        expect(errors.map((e) => e.code), isNot(contains('dispose_fields')));
      });
    });

    group('prefer_class_destructuring ignored_types', () {
      test('exempts a listed type', () async {
        final errors = await harness.analyze(
          _threePropertyCode,
          config: '''
rules:
  prefer_class_destructuring:
    ignored_types: [Foo]
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('prefer_class_destructuring')),
        );
      });

      test('leaves an unlisted type reporting', () async {
        final errors = await harness.analyze(
          _threePropertyCode,
          config: '''
rules:
  prefer_class_destructuring:
    ignored_types: [SomethingElse]
''',
        );

        expect(
          errors.map((e) => e.code),
          contains('prefer_class_destructuring'),
        );
      });
    });

    group('avoid_commented_out_code min_lines', () {
      test('reports a single commented-out line by default', () async {
        final errors = await harness.analyze(_oneLineCommentedCode);

        expect(errors.map((e) => e.code), contains('avoid_commented_out_code'));
      });

      test('min_lines: 2 silences a one-line block', () async {
        final errors = await harness.analyze(
          _oneLineCommentedCode,
          config: '''
rules:
  avoid_commented_out_code:
    min_lines: 2
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('avoid_commented_out_code')),
        );
      });

      test('min_lines: 2 still reports a two-line block', () async {
        final errors = await harness.analyze(
          _twoLineCommentedCode,
          config: '''
rules:
  avoid_commented_out_code:
    min_lines: 2
''',
        );

        expect(errors.map((e) => e.code), contains('avoid_commented_out_code'));
      });
    });

    group('avoid_duplicate_collection_elements ignore_literals', () {
      test('reports duplicate literals by default', () async {
        final errors = await harness.analyze(_duplicateLiteralCode);

        expect(
          errors.map((e) => e.code),
          contains('avoid_duplicate_collection_elements'),
        );
      });

      test('ignore_literals exempts them', () async {
        final errors = await harness.analyze(
          _duplicateLiteralCode,
          config: '''
rules:
  avoid_duplicate_collection_elements:
    ignore_literals: true
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('avoid_duplicate_collection_elements')),
        );
      });

      test('ignore_literals still reports a duplicate identifier', () async {
        final errors = await harness.analyze(
          _duplicateIdentifierCode,
          config: '''
rules:
  avoid_duplicate_collection_elements:
    ignore_literals: true
''',
        );

        expect(
          errors.map((e) => e.code),
          contains('avoid_duplicate_collection_elements'),
        );
      });
    });

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

    group('prefer_moving_to_variable', () {
      test('reports a repeated invocation chain with no config', () async {
        final errors = await harness.analyze(_repeatedChainCode);

        expect(
          errors.map((e) => e.code),
          contains('prefer_moving_to_variable'),
        );
      });

      test('allowed_duplicated_chains tolerates the second use', () async {
        final errors = await harness.analyze(
          _repeatedChainCode,
          config: '''
rules:
  prefer_moving_to_variable:
    allowed_duplicated_chains: 1
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('prefer_moving_to_variable')),
        );
      });

      test('a third use reports again at the same threshold', () async {
        // The asymmetric half: proves the option raised the bar rather than
        // switching the rule off.
        final errors = await harness.analyze(
          _thriceRepeatedChainCode,
          config: '''
rules:
  prefer_moving_to_variable:
    allowed_duplicated_chains: 1
''',
        );

        expect(
          errors.map((e) => e.code),
          contains('prefer_moving_to_variable'),
        );
      });

      test('ignored_invocations exempts the named method', () async {
        final errors = await harness.analyze(
          _repeatedChainCode,
          config: '''
rules:
  prefer_moving_to_variable:
    ignored_invocations: [of]
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('prefer_moving_to_variable')),
        );
      });

      test('ignored_invocations leaves other methods reporting', () async {
        final errors = await harness.analyze(
          _repeatedChainCode,
          config: '''
rules:
  prefer_moving_to_variable:
    ignored_invocations: [somethingElse]
''',
        );

        expect(
          errors.map((e) => e.code),
          contains('prefer_moving_to_variable'),
        );
      });

      test('ignored_targets exempts the named type', () async {
        final errors = await harness.analyze(
          _repeatedChainCode,
          config: '''
rules:
  prefer_moving_to_variable:
    ignored_targets: [Themer]
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('prefer_moving_to_variable')),
        );
      });

      test('min_chain_length governs pure property chains', () async {
        final errors = await harness.analyze(
          _repeatedPropertyChainCode,
          config: '''
rules:
  prefer_moving_to_variable:
    min_chain_length: 3
''',
        );

        expect(
          errors.map((e) => e.code),
          isNot(contains('prefer_moving_to_variable')),
        );
      });

      test('a property chain reports at the default length', () async {
        final errors = await harness.analyze(_repeatedPropertyChainCode);

        expect(
          errors.map((e) => e.code),
          contains('prefer_moving_to_variable'),
        );
      });
    });
  });
}

/// `Themer.of(context)` twice — one invocation chain, repeated.
const _repeatedChainCode = '''
class Themer {
  static Themer of(Object context) => Themer();
  int get primary => 0;
  int get secondary => 1;
}

int fn(Object context) {
  final a = Themer.of(context).primary;
  final b = Themer.of(context).secondary;
  return a + b;
}
''';

/// The same chain three times, so a threshold of one extra still reports.
const _thriceRepeatedChainCode = '''
class Themer {
  static Themer of(Object context) => Themer();
  int get primary => 0;
  int get secondary => 1;
}

int fn(Object context) {
  final a = Themer.of(context).primary;
  final b = Themer.of(context).secondary;
  final c = Themer.of(context).primary;
  return a + b + c;
}
''';

/// A pure property chain of two links, which `min_chain_length` governs.
const _repeatedPropertyChainCode = '''
class Inner {
  int get value => 0;
}

class Outer {
  Inner get inner => Inner();
}

int fn(Outer outer) {
  final a = outer.inner.value;
  final b = outer.inner.value;
  return a + b;
}
''';

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
    // `state` and `emit` exist so `emit_new_bloc_state_instances` can resolve
    // them; the suffix/prefix rules below only use these as bare type markers
    // and are unaffected by the extra members.
    newFile(join(blocRoot, 'lib', 'bloc.dart'), '''
class Bloc<Event, State> {
  late State state;
  void emit(State state) {}
  void safeEmit(State state) {}
  void handle<T extends Event>(void Function(T, void Function(State)) handler) {}
}
class Cubit<State> {
  late State state;
  void emit(State state) {}
  void safeEmit(State state) {}
}
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

  void _addFlutterPackages({required bool withHooks}) {
    final flutterRoot = convertPath('/pkg/flutter');
    final hooksRoot = convertPath('/pkg/flutter_hooks');

    newFile(join(flutterRoot, 'lib', 'widgets.dart'), r'''
const visibleForTesting = Object();

class Widget {
  const Widget();
}
class BuildContext {}
class StatelessWidget extends Widget {
  const StatelessWidget();
  Widget build(BuildContext context) => const Widget();
}
class StatefulWidget extends Widget {
  const StatefulWidget();
}
class State<T extends StatefulWidget> {
  Widget build(BuildContext context) => const Widget();
}
class RenderObject {}
class SizedBox extends Widget {
  const SizedBox({this.width, this.height, this.child});
  final double? width;
  final double? height;
  final Widget? child;
}
class Column extends Widget {
  const Column({this.children = const [], this.spacing = 0});
  final List<Widget> children;
  final double spacing;
}
class Row extends Widget {
  const Row({this.children = const [], this.spacing = 0});
  final List<Widget> children;
  final double spacing;
}
class Flex extends Widget {
  const Flex({this.children = const [], this.spacing = 0});
  final List<Widget> children;
  final double spacing;
}
class Wrap extends Widget {
  const Wrap({this.children = const []});
  final List<Widget> children;
}
class ListView extends Widget {
  const ListView({this.children = const []});
  final List<Widget> children;
}
class Padding extends Widget {
  const Padding({this.padding, this.child});
  final Object? padding;
  final Widget? child;
}
class Align extends Widget {
  const Align({this.child});
  final Widget? child;
}
''');

    if (withHooks) {
      newFile(join(hooksRoot, 'lib', 'flutter_hooks.dart'), r'''
import 'package:flutter/widgets.dart';
export 'package:flutter/widgets.dart';

class HookWidget extends Widget {
  const HookWidget();
  Widget build(BuildContext context) => const Widget();
}

T useState<T>(T value) => value;
''');
    }

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
      "name": "flutter",
      "rootUri": "${toUri(flutterRoot)}",
      "packageUri": "lib/"
    }${withHooks ? ''',
    {
      "name": "flutter_hooks",
      "rootUri": "${toUri(hooksRoot)}",
      "packageUri": "lib/"
    }''' : ''}
  ]
}
''');
  }

  /// Writes an extra library beside the file under analysis.
  ///
  /// Needed when a rule's option refers to a base type that must *not* be
  /// declared in the analyzed file — `TypeChecker.isSuperOf` is reflexive, so
  /// a locally declared base counts as its own subtype.
  void addLibrary(String fileName, String content) =>
      newFile(join(packagePath, 'lib', fileName), content);

  Future<List<protocol.AnalysisError>> analyze(
    String content, {
    String? config,
    String? optionsSection,
    String fileName = 'test.dart',
    bool withBloc = false,
    bool withFlutter = false,
    bool withHooks = false,
  }) async {
    final filePath = join(packagePath, 'lib', fileName);

    if (withBloc) _addBlocPackage();
    if (withFlutter || withHooks) {
      _addFlutterPackages(withHooks: withHooks);
    }

    newAnalysisOptionsYamlFile(packagePath, '''
plugins:
  many_lints:
    path: /many_lints
${optionsSection ?? ''}''');

    // Rules are opt-in as of 1.0.0, so a test asserting a rule's *default*
    // option behaviour still has to switch the rule on. A test that supplies
    // either config source enables the rule through that block, since
    // configuring a rule by name opts it in.
    //
    // The fallback is only written when neither source is given: a
    // `many_lints.yaml` wins outright over the analysis_options section, so
    // writing one unconditionally would silently defeat every test that
    // exercises the `optionsSection` route.
    if (config != null) {
      newFile(join(packagePath, ConfigLoader.fileName), config);
    } else if (optionsSection == null) {
      newFile(
        join(packagePath, ConfigLoader.fileName),
        'preset: opinionated\n',
      );
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
