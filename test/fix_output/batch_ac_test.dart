import 'package:test/test.dart';

import '../fix_harness.dart';

/// End-to-end tests for the text these quick fixes actually produce.
///
/// See [FixHarness] for why this drives a real plugin server.
void main() {
  late FixHarness harness;

  setUp(() async {
    harness = FixHarness();
    await harness.setUp();
  });

  tearDown(() async {
    await harness.tearDown();
  });

  const gestureDetectorWidgets = r'''
class Key {
  const Key(String value);
}

abstract class Widget {
  const Widget({Key? key});
}

class Text extends Widget {
  const Text(String data, {super.key});
}

class Container extends Widget {
  const Container({super.key, Widget? child});
}

class GestureDetector extends Widget {
  const GestureDetector({
    super.key,
    Widget? child,
    void Function()? onTap,
    void Function()? onLongPress,
  });
}
''';

  group('avoid_unnecessary_gesture_detector', () {
    test('replaces GestureDetector with its child', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';
Widget f() {
  return GestureDetector(
    child: Text('hello'),
  );
}
''',
        'avoid_unnecessary_gesture_detector',
        packages: {'flutter': gestureDetectorWidgets},
      );

      expect(fixed, contains("return Text('hello');"));
      expect(fixed, isNot(contains('GestureDetector')));
    });

    test(
      'replaces a childless GestureDetector call with nothing useful',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:flutter/flutter.dart';
Widget f() {
  return GestureDetector(child: Container());
}
''',
          'avoid_unnecessary_gesture_detector',
          packages: {'flutter': gestureDetectorWidgets},
        );

        expect(fixed, contains('return Container();'));
        expect(fixed, isNot(contains('GestureDetector')));
      },
    );
  });

  const hookWidgets = r'''
class Widget {}
class BuildContext {}
class StatelessWidget extends Widget {
  Widget build(BuildContext context) => Widget();
}
''';
  const flutterHooksSource = r'''
import 'package:flutter/flutter.dart';
class HookWidget extends Widget {
  Widget build(BuildContext context) => Widget();
}
class HookConsumerWidget extends Widget {
  Widget build(BuildContext context) => Widget();
}
T useState<T>(T initialData) => initialData;
''';

  group('avoid_unnecessary_hook_widgets', () {
    test('converts HookWidget to StatelessWidget', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
class MyWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    return Widget();
  }
}
''',
        'avoid_unnecessary_hook_widgets',
        packages: {'flutter': hookWidgets, 'flutter_hooks': flutterHooksSource},
      );

      expect(fixed, contains('class MyWidget extends StatelessWidget {'));
      expect(fixed, isNot(contains('HookWidget')));
    });

    test('converts HookConsumerWidget to StatelessWidget', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
class MyWidget extends HookConsumerWidget {
  @override
  Widget build(BuildContext context) {
    return Widget();
  }
}
''',
        'avoid_unnecessary_hook_widgets',
        packages: {
          'flutter': hookWidgets,
          'hooks_riverpod': r'''
import 'package:flutter/flutter.dart';
class HookConsumerWidget extends Widget {
  Widget build(BuildContext context) => Widget();
}
''',
        },
      );

      expect(fixed, contains('class MyWidget extends StatelessWidget {'));
      expect(fixed, isNot(contains('HookConsumerWidget')));
    });
  });

  group('avoid_unnecessary_overrides', () {
    test('removes a method that only calls super with the same args', () async {
      final fixed = await harness.applyFix(r'''
class Base {
  void foo(int x) {}
}

class Child extends Base {
  @override
  void foo(int x) {
    super.foo(x);
  }
}
''', 'avoid_unnecessary_overrides');

      expect(fixed, isNot(contains('@override')));
      expect(fixed, contains('class Child extends Base {}'));
    });

    test('removes a getter that only returns super', () async {
      final fixed = await harness.applyFix(r'''
class Base {
  int get value => 42;
}

class Child extends Base {
  @override
  int get value => super.value;
}
''', 'avoid_unnecessary_overrides');

      expect(fixed, isNot(contains('@override')));
      expect(fixed, contains('class Child extends Base {}'));
    });
  });

  const setStateWidgets = r'''
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
  void setState(void Function() fn) {}
  void initState() {}
  Widget build(BuildContext context);
}
''';

  group('avoid_unnecessary_setstate', () {
    test('inlines a block-body setState call in initState', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  String _data = '';

  @override
  void initState() {
    super.initState();
    setState(() {
      _data = 'Hello';
    });
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
        'avoid_unnecessary_setstate',
        packages: {'flutter': setStateWidgets},
      );

      expect(fixed, contains("_data = 'Hello';"));
      expect(fixed, isNot(contains('setState')));
    });

    test('removes an empty setState call entirely', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
        'avoid_unnecessary_setstate',
        packages: {'flutter': setStateWidgets},
      );

      expect(fixed, isNot(contains('setState')));
      // The fix removes the setState(() {}) call but leaves the blank
      // line it occupied — assert on the real produced whitespace.
      expect(fixed, contains('super.initState();\n    \n  }'));
    });

    test('inlines an expression-body setState call in build', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    setState(() => _count = 1);
    return const Widget();
  }
}
''',
        'avoid_unnecessary_setstate',
        packages: {'flutter': setStateWidgets},
      );

      expect(fixed, contains('_count = 1;'));
      expect(fixed, isNot(contains('setState')));
    });
  });

  const statefulWidgetPackage = r'''
class Widget {
  const Widget({Key? key});
}
class Key {}
class BuildContext {}
class StatelessWidget extends Widget {
  const StatelessWidget({super.key});
  Widget build(BuildContext context) => Widget();
}
class StatefulWidget extends Widget {
  const StatefulWidget({super.key});
  State createState();
}
class State<T extends StatefulWidget> {
  T get widget => throw '';
  void setState(void Function() fn) {}
  Widget build(BuildContext context) => Widget();
  void initState() {}
  void dispose() {}
}
class Text extends Widget {
  const Text(String data, {super.key});
}
''';

  group('avoid_unnecessary_stateful_widgets', () {
    test(
      'converts a StatefulWidget with only build() to StatelessWidget',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:flutter/flutter.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return Text('Hello');
  }
}
''',
          'avoid_unnecessary_stateful_widgets',
          packages: {'flutter': statefulWidgetPackage},
        );

        expect(fixed, contains('class MyWidget extends StatelessWidget'));
        expect(fixed, isNot(contains('_MyWidgetState')));
        expect(fixed, isNot(contains('createState')));
        expect(fixed, contains("return Text('Hello');"));
      },
    );

    test('preserves a helper method from the State class', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final String title = 'Hello';

  @override
  Widget build(BuildContext context) {
    return Text(title);
  }
}
''',
        'avoid_unnecessary_stateful_widgets',
        packages: {'flutter': statefulWidgetPackage},
      );

      expect(fixed, contains('class MyWidget extends StatelessWidget'));
      expect(fixed, contains("final String title = 'Hello';"));
      expect(fixed, isNot(contains('_MyWidgetState')));
    });
  });

  const paddingWidgets = r'''
class Widget {}
class Key {}
class EdgeInsets {
  static const EdgeInsets zero = EdgeInsets.all(0);
  const EdgeInsets.all(double value);
  const EdgeInsets.symmetric({double vertical = 0, double horizontal = 0});
}
class Padding extends Widget {
  Padding({Key? key, required EdgeInsets padding, Widget? child});
}
class Container extends Widget {
  Container({Key? key, EdgeInsets? padding, Widget? child});
}
class Text extends Widget {
  Text(String data);
}
''';

  group('avoid_wrapping_in_padding', () {
    test('moves padding onto the child widget', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';
Widget f() {
  return Padding(
    padding: EdgeInsets.all(8),
    child: Container(),
  );
}
''',
        'avoid_wrapping_in_padding',
        packages: {'flutter': paddingWidgets},
      );

      expect(fixed, contains('Container(padding: EdgeInsets.all(8))'));
      expect(fixed, isNot(contains('Padding(')));
    });

    test('preserves the key argument when moving padding', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';
Widget f() {
  return Padding(
    key: Key(),
    padding: EdgeInsets.all(8),
    child: Container(),
  );
}
''',
        'avoid_wrapping_in_padding',
        packages: {'flutter': paddingWidgets},
      );

      expect(
        fixed,
        contains('Container(key: Key(), padding: EdgeInsets.all(8))'),
      );
      expect(fixed, isNot(contains('Padding(')));
    });

    test('keeps existing child arguments when moving padding', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';
Widget f() {
  return Padding(
    padding: EdgeInsets.all(8),
    child: Container(child: Text('Hello')),
  );
}
''',
        'avoid_wrapping_in_padding',
        packages: {'flutter': paddingWidgets},
      );

      expect(
        fixed,
        contains("Container(child: Text('Hello'), padding: EdgeInsets.all(8))"),
      );
      expect(fixed, isNot(contains('Padding(')));
    });
  });

  const disposeFieldsWidgets = r'''
class Widget {}
class StatelessWidget extends Widget {
  Widget build() => throw UnimplementedError();
}
class StatefulWidget extends Widget {
  State createState() => throw UnimplementedError();
}
abstract class State<T extends StatefulWidget> {
  void dispose() {}
  Widget build();
}
class ChangeNotifier {
  void dispose() {}
}
class TextEditingController extends ChangeNotifier {}
''';

  group('dispose_fields', () {
    test('creates a dispose() method when none exists', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _controller = TextEditingController();

  @override
  Widget build() => Widget();
}
''',
        'dispose_fields',
        packages: {'flutter': disposeFieldsWidgets},
      );

      expect(fixed, contains('void dispose() {'));
      expect(fixed, contains('_controller.dispose();'));
      expect(fixed, contains('super.dispose();'));
    });

    test('inserts the disposal call into an existing dispose()', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build() => Widget();
}
''',
        'dispose_fields',
        packages: {'flutter': disposeFieldsWidgets},
      );

      final controllerDisposeIndex = fixed.indexOf('_controller.dispose();');
      final superDisposeIndex = fixed.indexOf('super.dispose();');
      expect(controllerDisposeIndex, greaterThan(0));
      expect(superDisposeIndex, greaterThan(controllerDisposeIndex));
    });
  });

  const riverpodDisposalSource = r'''
class Ref {
  T read<T>(Object provider) => throw '';
  T watch<T>(Object provider) => throw '';
  void onDispose(void Function() callback) {}
}

class Provider<T> {
  Provider(T Function(Ref ref) create);
}

abstract class Notifier<State> {
  Ref get ref => throw UnimplementedError();
  State get state => throw UnimplementedError();
  set state(State value) {}
  State build();
}
''';

  group('dispose_provided_instances', () {
    test(
      'adds ref.onDispose after the disposable instance is created',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
}

final provider = Provider<DisposableService>((ref) {
  final instance = DisposableService();
  return instance;
});
''',
          'dispose_provided_instances',
          packages: {'riverpod': riverpodDisposalSource},
        );

        expect(fixed, contains('final instance = DisposableService();'));
        expect(fixed, contains('ref.onDispose(instance.dispose);'));
        final declIndex = fixed.indexOf(
          'final instance = DisposableService();',
        );
        final onDisposeIndex = fixed.indexOf(
          'ref.onDispose(instance.dispose);',
        );
        expect(onDisposeIndex, greaterThan(declIndex));
      },
    );

    test('adds ref.onDispose inside a Notifier build() method', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
}

class MyNotifier extends Notifier<DisposableService> {
  @override
  DisposableService build() {
    final instance = DisposableService();
    return instance;
  }
}
''',
        'dispose_provided_instances',
        packages: {'riverpod': riverpodDisposalSource},
      );

      expect(fixed, contains('ref.onDispose(instance.dispose);'));
    });
  });

  const equatableSource = r'''
abstract class Equatable {
  const Equatable();
  List<Object?> get props;
}

mixin EquatableMixin {
  List<Object?> get props;
}
''';

  group('list_all_equatable_fields', () {
    test('appends the missing field to props', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:equatable/equatable.dart';

class Person extends Equatable {
  const Person(this.name, this.age);
  final String name;
  final int age;

  @override
  List<Object?> get props => [name];
}
''',
        'list_all_equatable_fields',
        packages: {'equatable': equatableSource},
      );

      expect(fixed, contains('List<Object?> get props => [name, age];'));
    });

    test('adds all fields when props is empty', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:equatable/equatable.dart';

class Person extends Equatable {
  const Person(this.name, this.age);
  final String name;
  final int age;

  @override
  List<Object?> get props => [];
}
''',
        'list_all_equatable_fields',
        packages: {'equatable': equatableSource},
      );

      expect(fixed, contains('List<Object?> get props => [name, age];'));
    });

    test('appends the missing field with EquatableMixin', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:equatable/equatable.dart';

class Person with EquatableMixin {
  Person(this.name, this.age);
  final String name;
  final int age;

  @override
  List<Object?> get props => [name];
}
''',
        'list_all_equatable_fields',
        packages: {'equatable': equatableSource},
      );

      expect(fixed, contains('List<Object?> get props => [name, age];'));
    });
  });

  const providerScopeWidgets = r'''
class Widget {}
class BuildContext {}
class StatelessWidget extends Widget {
  Widget build(BuildContext context) => Widget();
}
void runApp(Widget app) {}
''';
  const flutterRiverpodSource = r'''
import 'package:flutter/flutter.dart';
class ProviderContainer {}
class ProviderScope extends Widget {
  ProviderScope({Widget? child});
}
''';

  group('missing_provider_scope', () {
    test(
      'wraps the root widget with ProviderScope and adds the import',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:flutter/flutter.dart';

class MyApp extends StatelessWidget {}

void main() {
  runApp(MyApp());
}
''',
          'missing_provider_scope',
          packages: {
            'flutter': providerScopeWidgets,
            'flutter_riverpod': flutterRiverpodSource,
          },
        );

        expect(fixed, contains('runApp(ProviderScope(child: MyApp()))'));
        expect(
          fixed,
          contains("import 'package:flutter_riverpod/flutter_riverpod.dart';"),
        );
      },
    );

    test('wraps a non-scope wrapper widget passed to runApp', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';

class MyApp extends StatelessWidget {}
class Wrapper extends StatelessWidget {
  Wrapper({Widget? child});
}

void main() {
  runApp(Wrapper(child: MyApp()));
}
''',
        'missing_provider_scope',
        packages: {
          'flutter': providerScopeWidgets,
          'flutter_riverpod': flutterRiverpodSource,
        },
      );

      expect(
        fixed,
        contains('runApp(ProviderScope(child: Wrapper(child: MyApp())))'),
      );
    });
  });
}
