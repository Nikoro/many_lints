import 'package:test/test.dart';

import '../fix_harness.dart';

void main() {
  late FixHarness harness;

  setUp(() async {
    harness = FixHarness();
    await harness.setUp();
  });

  tearDown(() async {
    await harness.tearDown();
  });

  group('avoid_incorrect_image_opacity', () {
    const flutterImageOpacity = r'''
class Widget {
  const Widget({Key? key});
}

class Key {}

class Opacity extends Widget {
  const Opacity({super.key, required double opacity, Widget? child});

  static Opacity create({required double opacity, Widget? child}) =>
      Opacity(opacity: opacity, child: child);
}

class Image extends Widget {
  const Image({super.key, String? semanticLabel, Animation<double>? opacity});

  const Image.asset(String name, {Key? key, Animation<double>? opacity});
}

class Animation<T> {
  const Animation();
}

class AlwaysStoppedAnimation<T> extends Animation<T> {
  const AlwaysStoppedAnimation(T value);
}
''';

    test('moves opacity into the Image constructor', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';
Widget f() {
  return Opacity(
    opacity: 0.5,
    child: Image(semanticLabel: 'test'),
  );
}
''',
        'avoid_incorrect_image_opacity',
        packages: {'flutter': flutterImageOpacity},
      );

      expect(
        fixed,
        contains(
          "Image(semanticLabel: 'test', opacity: AlwaysStoppedAnimation(0.5))",
        ),
      );
      expect(fixed, isNot(contains('Opacity(')));
    });

    test(
      'adds opacity via the Opacity.create factory (MethodInvocation)',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:flutter/flutter.dart';
Widget f() {
  return Opacity.create(opacity: 0.3, child: Image.asset('path/to/image.png'));
}
''',
          'avoid_incorrect_image_opacity',
          packages: {'flutter': flutterImageOpacity},
        );

        expect(
          fixed,
          contains(
            "Image.asset('path/to/image.png', opacity: AlwaysStoppedAnimation(0.3))",
          ),
        );
        expect(fixed, isNot(contains('Opacity.create')));
      },
    );
  });

  group('avoid_inverted_boolean_checks', () {
    test('rewrites a negated greater-than', () async {
      final fixed = await harness.applyFix(r'''
bool check(int a, int b) {
  return !(a > b);
}
''', 'avoid_inverted_boolean_checks');

      expect(fixed, contains('return a <= b;'));
    });

    test('rewrites a negated greater-or-equal', () async {
      final fixed = await harness.applyFix(r'''
bool check(int a, int b) {
  return !(a >= b);
}
''', 'avoid_inverted_boolean_checks');

      expect(fixed, contains('return a < b;'));
    });

    test('rewrites a negated less-than', () async {
      final fixed = await harness.applyFix(r'''
bool check(int a, int b) {
  return !(a < b);
}
''', 'avoid_inverted_boolean_checks');

      expect(fixed, contains('return a >= b;'));
    });
  });

  group('avoid_map_keys_contains', () {
    test('replaces a simple variable target', () async {
      final fixed = await harness.applyFix(r'''
bool check(Map<String, int> map, String key) {
  return map.keys.contains(key);
}
''', 'avoid_map_keys_contains');

      expect(fixed, contains('return map.containsKey(key);'));
      expect(fixed, isNot(contains('.keys.contains')));
    });

    test('replaces a complex property-access target', () async {
      final fixed = await harness.applyFix(r'''
class Holder {
  Map<String, int> get map => {};
}

bool check(Holder holder, String key) {
  return holder.map.keys.contains(key);
}
''', 'avoid_map_keys_contains');

      expect(fixed, contains('return holder.map.containsKey(key);'));
      expect(fixed, isNot(contains('.keys.contains')));
    });
  });

  group('avoid_notifier_constructors', () {
    const riverpodNotifier = r'''
abstract class Notifier<State> {
  State get state => throw UnimplementedError();
  set state(State value) {}
  State build();
}

abstract class AsyncNotifier<State> {
  State get state => throw UnimplementedError();
  set state(State value) {}
  Future<State> build();
}
''';

    test('removes a constructor with a body', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:riverpod/riverpod.dart';

class Counter extends Notifier<int> {
  var _initial = 0;

  Counter() {
    _initial = 1;
  }

  @override
  int build() => _initial;
}
''',
        'avoid_notifier_constructors',
        packages: {'riverpod': riverpodNotifier},
      );

      expect(fixed, isNot(contains('Counter() {')));
      expect(fixed, contains('int build() => _initial;'));
    });

    test('removes a named constructor with an initializer list', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:riverpod/riverpod.dart';

class Counter extends AsyncNotifier<int> {
  final int _initial;

  Counter.custom() : _initial = 1;

  @override
  Future<int> build() async => _initial;
}
''',
        'avoid_notifier_constructors',
        packages: {'riverpod': riverpodNotifier},
      );

      expect(fixed, isNot(contains('Counter.custom()')));
      expect(fixed, contains('Future<int> build() async => _initial;'));
    });
  });

  group('avoid_only_rethrow', () {
    test('unwraps the try body when it is the only catch clause', () async {
      final fixed = await harness.applyFix(r'''
void f() {
  try {
    print('hello');
  } catch (e) {
    rethrow;
  }
}
''', 'avoid_only_rethrow');

      expect(fixed, contains("print('hello');"));
      expect(fixed, isNot(contains('try')));
      expect(fixed, isNot(contains('rethrow')));
    });

    test(
      'removes only the rethrow-only clause when a finally block exists',
      () async {
        final fixed = await harness.applyFix(r'''
void f() {
  try {
    print('hello');
  } catch (e) {
    rethrow;
  } finally {
    print('cleanup');
  }
}
''', 'avoid_only_rethrow');

        expect(fixed, contains('try {'));
        expect(fixed, contains("print('cleanup');"));
        expect(fixed, isNot(contains('rethrow')));
      },
    );
  });

  group('avoid_redundant_else', () {
    test('hoists a single-statement else body', () async {
      final fixed = await harness.applyFix(r'''
int f(int x) {
  if (x > 0) {
    return x;
  } else {
    return -x;
  }
}
''', 'avoid_redundant_else');

      expect(fixed, contains('return x;'));
      expect(fixed, contains('return -x;'));
      expect(fixed, isNot(contains('else')));
    });

    test('hoists a multi-statement else block', () async {
      final fixed = await harness.applyFix(r'''
int f(int x) {
  if (x > 0) {
    return x;
  } else {
    print('negative');
    return -x;
  }
}
''', 'avoid_redundant_else');

      expect(fixed, contains("print('negative');"));
      expect(fixed, contains('return -x;'));
      expect(fixed, isNot(contains('else')));
    });
  });

  group('avoid_ref_read_inside_build', () {
    const flutterWidgetsBase = r'''
class Widget {}
class BuildContext {}
''';
    final flutterRiverpodMock =
        '''
$flutterWidgetsBase
class Ref {
  T read<T>(Object provider) => throw '';
  T watch<T>(Object provider) => throw '';
}
class WidgetRef extends Ref {}
class ConsumerWidget extends Widget {
  Widget build(BuildContext context, WidgetRef ref) => Widget();
}
''';

    test(
      'replaces ref.read with ref.watch in a ConsumerWidget build',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.read(Object());
    return Widget();
  }
}
''',
          'avoid_ref_read_inside_build',
          packages: {'flutter_riverpod': flutterRiverpodMock},
        );

        expect(fixed, contains('ref.watch(Object())'));
        expect(fixed, isNot(contains('ref.read')));
      },
    );

    test(
      'replaces only the first of multiple ref.read calls it fixes',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.read(Object());
    final b = ref.read(Object());
    return Widget();
  }
}
''',
          'avoid_ref_read_inside_build',
          packages: {'flutter_riverpod': flutterRiverpodMock},
        );

        expect(fixed, contains('final a = ref.watch(Object());'));
      },
    );
  });

  group('avoid_single_field_destructuring', () {
    test(
      'replaces object-pattern destructuring with property access',
      () async {
        final fixed = await harness.applyFix(r'''
class Foo {
  final int value;
  Foo(this.value);
}

void f(Foo input) {
  final Foo(:value) = input;
}
''', 'avoid_single_field_destructuring');

        expect(fixed, contains('final value = input.value;'));
        expect(fixed, isNot(contains('Foo(:value)')));
      },
    );

    test('replaces a renamed named field with property access', () async {
      final fixed = await harness.applyFix(r'''
class Foo {
  final int value;
  Foo(this.value);
}

void f(Foo input) {
  final Foo(value: v) = input;
}
''', 'avoid_single_field_destructuring');

      expect(fixed, contains('final v = input.value;'));
    });

    test(
      'replaces record-pattern destructuring with property access',
      () async {
        final fixed = await harness.applyFix(r'''
void f(({int length}) record) {
  final (:length) = record;
}
''', 'avoid_single_field_destructuring');

        expect(fixed, contains('final length = record.length;'));
      },
    );
  });

  group('avoid_state_constructors', () {
    const flutterState = r'''
class BuildContext {}

class Widget {
  const Widget({Key? key});
}

class Key {}

class StatefulWidget extends Widget {
  const StatefulWidget({super.key});
  State createState() => throw UnimplementedError();
}

abstract class State<T extends StatefulWidget> {
  BuildContext get context => BuildContext();
  bool get mounted => true;
  void setState(void Function() fn) {}
  void initState() {}
  void dispose() {}
  Widget build(BuildContext context);
}
''';

    test('deletes a constructor with a body', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late String _data;

  _MyWidgetState() {
    _data = 'Hello';
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
        'avoid_state_constructors',
        packages: {'flutter': flutterState},
      );

      expect(fixed, isNot(contains('_MyWidgetState() {')));
      expect(fixed, contains('late String _data;'));
      expect(
        fixed,
        contains('Widget build(BuildContext context) => const Widget();'),
      );
    });

    test('deletes a named constructor with an initializer list', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState.custom();
}

class _MyWidgetState extends State<MyWidget> {
  final String _data;

  _MyWidgetState.custom() : _data = 'custom';

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
        'avoid_state_constructors',
        packages: {'flutter': flutterState},
      );

      expect(fixed, isNot(contains("_data = 'custom'")));
      expect(fixed, contains('final String _data;'));
      expect(
        fixed,
        contains('State<MyWidget> createState() => _MyWidgetState.custom();'),
      );
    });
  });

  group('avoid_throw_in_catch_block', () {
    test(
      'preserves the stack trace when the catch already has a parameter',
      () async {
        final fixed = await harness.applyFix(r'''
void f() {
  try {
    print('hello');
  } catch (e, s) {
    print(s);
    throw Exception('error');
  }
}
''', 'avoid_throw_in_catch_block');

        expect(
          fixed,
          contains("Error.throwWithStackTrace(Exception('error'), s);"),
        );
      },
    );

    test('adds a stack trace parameter when the catch has none', () async {
      final fixed = await harness.applyFix(r'''
void f() {
  try {
    print('hello');
  } catch (e) {
    throw Exception('wrapped');
  }
}
''', 'avoid_throw_in_catch_block');

      expect(fixed, contains('catch (e, stackTrace)'));
      expect(
        fixed,
        contains(
          "Error.throwWithStackTrace(Exception('wrapped'), stackTrace);",
        ),
      );
    });

    test(
      'adds a catch clause with a stack param to an on-clause-only catch',
      () async {
        final fixed = await harness.applyFix(r'''
void f() {
  try {
    print('hello');
  } on Object {
    throw Exception('wrapped');
  }
}
''', 'avoid_throw_in_catch_block');

        expect(fixed, contains('on Object catch (_, stackTrace) {'));
        expect(
          fixed,
          contains(
            "Error.throwWithStackTrace(Exception('wrapped'), stackTrace);",
          ),
        );
      },
    );
  });

  group('avoid_unnecessary_consumer_widgets', () {
    const flutterConsumerWidgets = r'''
class Widget {}
class BuildContext {}
class StatelessWidget extends Widget {
  Widget build(BuildContext context) => Widget();
}
class StatefulWidget extends Widget {
  State createState() => throw '';
}
class State<T extends StatefulWidget> {
  Widget build(BuildContext context) => Widget();
  void setState(void Function() fn) {}
}
''';
    final flutterRiverpodConsumer = '''
import 'package:flutter/flutter.dart';
class WidgetRef {
  T watch<T>(Object provider) => throw '';
  T read<T>(Object provider) => throw '';
}
class ConsumerWidget extends Widget {
  Widget build(BuildContext context, WidgetRef ref) => Widget();
}
class ConsumerStatefulWidget extends StatefulWidget {}
class ConsumerState<T extends ConsumerStatefulWidget> extends State<T> {
  WidgetRef get ref => throw '';
}
''';

    test('converts an unused ConsumerWidget to StatelessWidget', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Widget();
  }
}
''',
        'avoid_unnecessary_consumer_widgets',
        packages: {
          'flutter': flutterConsumerWidgets,
          'flutter_riverpod': flutterRiverpodConsumer,
        },
      );

      expect(fixed, contains('class MyWidget extends StatelessWidget {'));
      expect(fixed, contains('Widget build(BuildContext context) {'));
      expect(fixed, isNot(contains('WidgetRef ref')));
    });

    test(
      'converts an unused ConsumerStatefulWidget to StatefulWidget',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:flutter/flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
class MyWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyWidget> createState() => _MyWidgetState();
}
class _MyWidgetState extends ConsumerState<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return Widget();
  }
}
''',
          'avoid_unnecessary_consumer_widgets',
          packages: {
            'flutter': flutterConsumerWidgets,
            'flutter_riverpod': flutterRiverpodConsumer,
          },
        );

        expect(fixed, contains('class MyWidget extends StatefulWidget {'));
      },
    );
  });
}
