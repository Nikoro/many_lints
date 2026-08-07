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

  const blocPackage = {
    'bloc': r'''
class Bloc<Event, State> {}
class Cubit<State> {}
''',
  };

  const riverpodSuffixPackage = {
    'riverpod': r'''
class Notifier<State> {}
''',
  };

  group('use_bloc_suffix', () {
    test('adds the Bloc suffix to the class name', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:bloc/bloc.dart';
class Counter extends Bloc<String, int> {}
''',
        'use_bloc_suffix',
        packages: blocPackage,
      );

      expect(fixed, contains('class CounterBloc extends Bloc<String, int>'));
    });

    test('also renames a same-named unnamed constructor', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:bloc/bloc.dart';
class Counter extends Bloc<String, int> {
  Counter() : super(0);
}
''',
        'use_bloc_suffix',
        packages: blocPackage,
      );

      expect(fixed, contains('class CounterBloc extends Bloc<String, int>'));
      expect(fixed, contains('CounterBloc() : super(0);'));
      expect(fixed, isNot(contains('Counter()')));
    });
  });

  group('use_cubit_suffix', () {
    test('adds the Cubit suffix to the class name', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:bloc/bloc.dart';
class Counter extends Cubit<int> {}
''',
        'use_cubit_suffix',
        packages: blocPackage,
      );

      expect(fixed, contains('class CounterCubit extends Cubit<int>'));
    });

    test('also renames a same-named unnamed constructor', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:bloc/bloc.dart';
class Counter extends Cubit<int> {
  Counter() : super(0);
}
''',
        'use_cubit_suffix',
        packages: blocPackage,
      );

      expect(fixed, contains('class CounterCubit extends Cubit<int>'));
      expect(fixed, contains('CounterCubit() : super(0);'));
      expect(fixed, isNot(contains('Counter()')));
    });
  });

  group('use_notifier_suffix', () {
    test('adds the Notifier suffix to the class name', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:riverpod/riverpod.dart';
class Counter extends Notifier<int> {}
''',
        'use_notifier_suffix',
        packages: riverpodSuffixPackage,
      );

      expect(fixed, contains('class CounterNotifier extends Notifier<int>'));
    });

    test('also renames a same-named unnamed constructor', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:riverpod/riverpod.dart';
class Counter extends Notifier<int> {
  Counter();
}
''',
        'use_notifier_suffix',
        packages: riverpodSuffixPackage,
      );

      expect(fixed, contains('class CounterNotifier extends Notifier<int>'));
      expect(fixed, contains('CounterNotifier();'));
      expect(fixed, isNot(contains('  Counter();')));
    });
  });

  group('use_closest_build_context', () {
    const flutterBuildContext = {
      'flutter': r'''
class Widget {}
class BuildContext {}
class StatelessWidget extends Widget {
  Widget build(BuildContext context) => Widget();
}
class Builder extends Widget {
  Builder({required Widget Function(BuildContext context) builder});
}
class LayoutBuilder extends Widget {
  LayoutBuilder({required Widget Function(BuildContext context, Object constraints) builder});
}
class Text extends Widget {
  Text(String data);
}
''',
    };

    test(
      'renames the inner Builder parameter to match the outer context',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:flutter/flutter.dart';
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Builder(builder: (_) {
      return _buildMyWidget(context);
    });
  }
  Widget _buildMyWidget(BuildContext ctx) => Text('hello');
}
''',
          'use_closest_build_context',
          packages: flutterBuildContext,
        );

        expect(fixed, contains('return Builder(builder: (context) {'));
      },
    );

    test(
      'renames the inner LayoutBuilder parameter to match the outer context',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:flutter/flutter.dart';
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      return _buildMyWidget(context);
    });
  }
  Widget _buildMyWidget(BuildContext ctx) => Text('hello');
}
''',
          'use_closest_build_context',
          packages: flutterBuildContext,
        );

        expect(
          fixed,
          contains('return LayoutBuilder(builder: (context, constraints) {'),
        );
      },
    );
  });

  group('use_dedicated_media_query_methods', () {
    const mediaQueryPackage = {
      'flutter': r'''
class BuildContext {}
class Size {
  final double width;
  final double height;
  const Size(this.width, this.height);
}
class EdgeInsets {
  static const EdgeInsets zero = EdgeInsets.all(0);
  const EdgeInsets.all(double value);
}
class Orientation { static const portrait = Orientation._(); const Orientation._(); }
class MediaQueryData {
  final Size size;
  final Orientation orientation;
  final double devicePixelRatio;
  final double textScaleFactor;
  final EdgeInsets padding;
  final EdgeInsets viewInsets;
  final EdgeInsets viewPadding;
  const MediaQueryData({
    this.size = const Size(0, 0),
    this.orientation = Orientation.portrait,
    this.devicePixelRatio = 1.0,
    this.textScaleFactor = 1.0,
    this.padding = EdgeInsets.zero,
    this.viewInsets = EdgeInsets.zero,
    this.viewPadding = EdgeInsets.zero,
  });
}
class MediaQuery {
  static MediaQueryData of(BuildContext context) => MediaQueryData();
  static MediaQueryData? maybeOf(BuildContext context) => MediaQueryData();
  static Size sizeOf(BuildContext context) => const Size(0, 0);
}
''',
    };

    test(
      'replaces MediaQuery.of(context).size with MediaQuery.sizeOf(context)',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:flutter/flutter.dart';
void f(BuildContext context) {
  MediaQuery.of(context).size;
}
''',
          'use_dedicated_media_query_methods',
          packages: mediaQueryPackage,
        );

        expect(fixed, contains('MediaQuery.sizeOf(context);'));
      },
    );

    test(
      'replaces MediaQuery.maybeOf(context)?.size with the maybe-dedicated method',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:flutter/flutter.dart';
void f(BuildContext context) {
  MediaQuery.maybeOf(context)?.size;
}
''',
          'use_dedicated_media_query_methods',
          packages: mediaQueryPackage,
        );

        expect(fixed, contains('MediaQuery.maybeSizeOf(context);'));
      },
    );
  });

  group('use_existing_destructuring', () {
    test(
      'adds the missing field to the pattern and replaces the access',
      () async {
        final fixed = await harness.applyFix(r'''
class Foo {
  final int value;
  final int another;
  Foo(this.value, this.another);
}

void f(Foo variable) {
  final Foo(:value) = variable;
  print(variable.another);
}
''', 'use_existing_destructuring');

        expect(fixed, contains('final Foo(:value, :another) = variable;'));
        expect(fixed, contains('print(another);'));
      },
    );

    test('appends after the last of several destructured fields', () async {
      final fixed = await harness.applyFix(r'''
class Bar {
  final int a;
  final int b;
  final int c;
  Bar(this.a, this.b, this.c);
}

void f(Bar bar) {
  final Bar(:a) = bar;
  print(bar.b);
  print(bar.c);
}
''', 'use_existing_destructuring');

      expect(fixed, contains('final Bar(:a, :b) = bar;'));
      expect(fixed, contains('print(b);'));
    });
  });

  group('use_existing_variable', () {
    test(
      'replaces a duplicated property access with the existing variable',
      () async {
        final fixed = await harness.applyFix(r'''
void fn(String value) {
  final some = value.length.isOdd;
  print(value.length.isOdd);
}
''', 'use_existing_variable');

        expect(fixed, contains('print(some);'));
      },
    );

    test(
      'replaces a duplicated method call with the existing variable',
      () async {
        final fixed = await harness.applyFix(r'''
void fn(List<int> list) {
  final copy = list.toList();
  print(list.toList());
}
''', 'use_existing_variable');

        expect(fixed, contains('print(copy);'));
      },
    );
  });

  group('use_gap', () {
    const gapPackages = {
      'flutter': r'''
class Widget {
  const Widget();
}
class Key {}
class Column extends Widget {
  const Column({Key? key, List<Widget>? children});
}
class Row extends Widget {
  const Row({Key? key, List<Widget>? children});
}
class SizedBox extends Widget {
  const SizedBox({Key? key, double? width, double? height, Widget? child});
}
class Container extends Widget {
  const Container({Key? key, double? width, double? height});
}
class Padding extends Widget {
  const Padding({Key? key, required EdgeInsetsGeometry padding, Widget? child});
}
class EdgeInsetsGeometry {
  const EdgeInsetsGeometry();
}
class EdgeInsets extends EdgeInsetsGeometry {
  const EdgeInsets.only({double left = 0, double top = 0, double right = 0, double bottom = 0});
  const EdgeInsets.all(double value);
}
''',
      'gap': r'''
import 'package:flutter/flutter.dart';
class Gap extends Widget {
  const Gap(double size);
}
''',
    };

    test('replaces a SizedBox spacer with Gap', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';
Widget f() {
  return Column(children: [Container(height: 20), SizedBox(height: 20), Container(height: 20)]);
}
''',
        'use_gap',
        packages: gapPackages,
      );

      expect(fixed, contains('Gap(20)'));
      expect(fixed, isNot(contains('SizedBox')));
    });

    test(
      'replaces a leading Padding-as-spacer with Gap before the child',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:flutter/flutter.dart';
Widget f() {
  return Column(children: [Padding(padding: EdgeInsets.only(top: 20), child: Container()), Container(height: 20)]);
}
''',
          'use_gap',
          packages: gapPackages,
        );

        expect(fixed, contains('Gap(20), Container()'));
        expect(fixed, isNot(contains('Padding')));
      },
    );

    test(
      'replaces a trailing Padding-as-spacer with Gap after the child',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:flutter/flutter.dart';
Widget f() {
  return Column(children: [Padding(padding: EdgeInsets.only(bottom: 20), child: Container()), Container(height: 20)]);
}
''',
          'use_gap',
          packages: gapPackages,
        );

        expect(fixed, contains('Container(), Gap(20)'));
        expect(fixed, isNot(contains('Padding')));
      },
    );
  });

  group('use_ref_and_state_synchronously', () {
    const riverpodRefPackage = {
      'riverpod': r'''
class Ref {
  T read<T>(Object provider) => throw '';
  T watch<T>(Object provider) => throw '';
  void listen(Object provider, void Function(dynamic, dynamic) listener) {}
  bool get mounted => true;
}

class Notifier<T> {
  Ref get ref => throw '';
  T get state => throw '';
  set state(T value) {}
}

class AsyncNotifier<T> {
  Ref get ref => throw '';
  T get state => throw '';
  set state(T value) {}
}
''',
    };

    test(
      'inserts a ref.mounted guard before a ref.read after an await',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  Future<void> doWork() async {
    await Future<void>.delayed(Duration(seconds: 1));
    ref.read(Object());
  }
}
''',
          'use_ref_and_state_synchronously',
          packages: riverpodRefPackage,
        );

        expect(
          fixed,
          contains('if (!ref.mounted) return;\n    ref.read(Object());'),
        );
      },
    );

    test(
      'inserts a ref.mounted guard before a state assignment after an await',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:riverpod/riverpod.dart';

class MyNotifier extends Notifier<int> {
  Future<void> doWork() async {
    await Future<void>.delayed(Duration(seconds: 1));
    state = 42;
  }
}
''',
          'use_ref_and_state_synchronously',
          packages: riverpodRefPackage,
        );

        expect(fixed, contains('if (!ref.mounted) return;\n    state = 42;'));
      },
    );
  });

  group('use_ref_read_synchronously', () {
    const flutterRiverpodPackages = {
      'flutter': r'''
class BuildContext {
  bool get mounted => true;
}

class Widget {}
class StatelessWidget extends Widget {
  Widget build(BuildContext context) => Widget();
}
''',
      'flutter_riverpod': r'''
import 'package:flutter/flutter.dart';

class WidgetRef {
  T read<T>(Object provider) => throw '';
  T watch<T>(Object provider) => throw '';
  void listen(Object provider, void Function(dynamic, dynamic) listener) {}
}

class ConsumerWidget extends StatelessWidget {
  Widget build(BuildContext context, [WidgetRef? ref]) => Widget();
}

class ConsumerState<T extends ConsumerWidget> {
  WidgetRef get ref => throw '';
  bool get mounted => true;
  BuildContext get context => throw '';
  Widget build(BuildContext context) => Widget();
}
''',
    };

    test(
      'inserts a mounted guard before ref.read in a build callback',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:flutter/flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, [WidgetRef? ref]) {
    final onTap = () async {
      await Future<void>.delayed(Duration(seconds: 1));
      ref!.read(Object());
    };
    return StatelessWidget();
  }
}
''',
          'use_ref_read_synchronously',
          packages: flutterRiverpodPackages,
        );

        expect(
          fixed,
          contains('if (!mounted) return;\n      ref!.read(Object());'),
        );
      },
    );

    test(
      'inserts a mounted guard before ref.read in a ConsumerState build callback',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:flutter/flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState extends ConsumerState<ConsumerWidget> {
  @override
  Widget build(BuildContext context) {
    final onTap = () async {
      await Future<void>.delayed(Duration(seconds: 1));
      ref.read(Object());
    };
    return StatelessWidget();
  }
}
''',
          'use_ref_read_synchronously',
          packages: flutterRiverpodPackages,
        );

        expect(
          fixed,
          contains('if (!mounted) return;\n      ref.read(Object());'),
        );
      },
    );
  });

  group('use_sliver_prefix', () {
    const sliverPackage = {
      'flutter': r'''
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
}
class SliverList extends Widget {
  const SliverList({super.key});
}
''',
    };

    test(
      'adds the Sliver prefix to a StatelessWidget returning a sliver',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:flutter/flutter.dart';
class MyList extends StatelessWidget {
  const MyList({super.key});
  @override
  Widget build(BuildContext context) => SliverList();
}
''',
          'use_sliver_prefix',
          packages: sliverPackage,
        );

        expect(fixed, contains('class SliverMyList extends StatelessWidget'));
      },
    );

    test(
      'adds the Sliver prefix to a StatefulWidget whose State returns a sliver',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:flutter/flutter.dart';
class MyList extends StatefulWidget {
  const MyList({super.key});
  @override
  State<MyList> createState() => _MyListState();
}
class _MyListState extends State<MyList> {
  @override
  Widget build(BuildContext context) => SliverList();
}
''',
          'use_sliver_prefix',
          packages: sliverPackage,
        );

        expect(fixed, contains('class SliverMyList extends StatefulWidget'));
        expect(fixed, contains('State<MyList> createState()'));
      },
    );
  });
}
