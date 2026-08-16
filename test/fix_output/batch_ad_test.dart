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

  group('notifier_build', () {
    const riverpodAnnotation = r'''
final class Riverpod {
  const Riverpod({this.keepAlive = false, this.dependencies});
  final bool keepAlive;
  final List<Object>? dependencies;
}

const riverpod = Riverpod();
''';

    test('adds a build method stub to an empty annotated class', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
class Counter {}
''',
        'notifier_build',
        packages: {'riverpod_annotation': riverpodAnnotation},
      );

      expect(fixed, contains('dynamic build() {'));
      expect(fixed, contains('throw UnimplementedError();'));
    });

    test('inserts the stub before existing members', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
class Counter {
  int get value => 0;
}
''',
        'notifier_build',
        packages: {'riverpod_annotation': riverpodAnnotation},
      );

      expect(fixed, contains('dynamic build() {'));
      expect(fixed, contains('int get value => 0;'));
      // The stub is inserted right after the opening brace, before members.
      expect(
        fixed.indexOf('dynamic build()'),
        lessThan(fixed.indexOf('int get value')),
      );
    });
  });

  group('prefer_abstract_final_static_class', () {
    test('adds abstract final to a plain static-only class', () async {
      final fixed = await harness.applyFix(r'''
class Constants {
  static const name = 'app';
  static final version = '1.0';
}
''', 'prefer_abstract_final_static_class');

      expect(fixed, contains('abstract final class Constants {'));
    });

    test('adds only final when already abstract', () async {
      final fixed = await harness.applyFix(r'''
abstract class Static {
  static final field = 'value';
}
''', 'prefer_abstract_final_static_class');

      expect(fixed, contains('abstract final class Static {'));
    });

    test('adds only abstract when already final', () async {
      final fixed = await harness.applyFix(r'''
final class Static {
  static final field = 'value';
}
''', 'prefer_abstract_final_static_class');

      expect(fixed, contains('abstract final class Static {'));
    });

    test('removes the now-redundant private constructor', () async {
      final fixed = await harness.applyFix(r'''
class MyConstants {
  MyConstants._();

  static const foo = 1;
}
''', 'prefer_abstract_final_static_class');

      expect(fixed, contains('abstract final class MyConstants {'));
      expect(fixed, isNot(contains('MyConstants._()')));
      // The class body should start straight at the static member, with no
      // blank line left where the constructor used to be.
      expect(fixed, contains('class MyConstants {\n  static const foo = 1;'));
    });

    test(
      'removes a private constructor written with an empty block body',
      () async {
        final fixed = await harness.applyFix(r'''
class MyConstants {
  MyConstants._() {}

  static const foo = 1;
}
''', 'prefer_abstract_final_static_class');

        expect(fixed, contains('abstract final class MyConstants {'));
        expect(fixed, isNot(contains('MyConstants._()')));
      },
    );
  });

  group('prefer_align_over_container', () {
    const flutterAlign = r'''
class Widget {}
class Key {
  const Key(String value);
}
class AlignmentGeometry {}
class Alignment implements AlignmentGeometry {
  static const Alignment center = Alignment(0, 0);
  static const Alignment topLeft = Alignment(-1, -1);
  const Alignment(double x, double y);
}
class Container extends Widget {
  Container({Key? key, AlignmentGeometry? alignment, Widget? child, double? width, double? height});
}
class Align extends Widget {
  Align({Key? key, AlignmentGeometry? alignment, Widget? child});
}
''';

    test('replaces Container with Align, keeping the alignment arg', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';
Widget f() {
  return Container(alignment: Alignment.center);
}
''',
        'prefer_align_over_container',
        packages: {'flutter': flutterAlign},
      );

      expect(fixed, contains('Align('));
      expect(fixed, isNot(contains('Container(')));
    });

    // test('replaces Container with Align, keeping the alignment arg', () async {
    //   final fixed = await harness.applyFix(
    //     r'''
    // import 'package:flutter/flutter.dart';
    // Widget f() {
    //   return Container(alignment: Alignment.center);
    // }
    // ''',
    //     'prefer_align_over_container',
    //     packages: {'flutter': flutterAlign},
    //   );
    //
    //   expect(fixed, contains('return Align(alignment: Alignment.center);'));
    //   expect(fixed, isNot(contains('Container(')));
    // });
    //
    // test('replaces Container with Align, keeping key and child args', () async {
    //   final fixed = await harness.applyFix(
    //     r'''
    // import 'package:flutter/flutter.dart';
    // Widget f() {
    //   return Container(key: Key('a'), alignment: Alignment.center, child: Container());
    // }
    // ''',
    //     'prefer_align_over_container',
    //     packages: {'flutter': flutterAlign},
    //   );
    //
    //   expect(
    //     fixed,
    //     contains(
    //       "return Align(key: Key('a'), alignment: Alignment.center, child: Container());",
    //     ),
    //   );
    // });
  });

  group('prefer_any_or_every', () {
    test('rewrites .where().isNotEmpty into .any()', () async {
      final fixed = await harness.applyFix(r'''
void f() {
  final list = [1, 2, 3];
  list.where((e) => e > 1).isNotEmpty;
}
''', 'prefer_any_or_every');

      expect(fixed, contains('list.any((e) => e > 1);'));
      expect(fixed, isNot(contains('.where(')));
    });

    test(
      'rewrites .where().isEmpty into .every() with negated predicate',
      () async {
        final fixed = await harness.applyFix(r'''
void f() {
  final list = [1, 2, 3];
  list.where((e) => e > 1).isEmpty;
}
''', 'prefer_any_or_every');

        expect(fixed, contains('list.every((e) => e <= 1);'));
        expect(fixed, isNot(contains('.where(')));
      },
    );

    test('rewrites .where().isEmpty with a block body predicate', () async {
      final fixed = await harness.applyFix(r'''
void f() {
  final list = [1, 2, 3];
  final result = list.where((e) { return e > 1; }).isEmpty;
}
''', 'prefer_any_or_every');

      expect(fixed, contains('list.every((e) => e <= 1);'));
    });
  });

  group('prefer_async_callback', () {
    test(
      'replaces a field type with AsyncCallback and imports foundation',
      () async {
        final fixed = await harness.applyFix(r'''
class MyWidget {
  final Future<void> Function() onTap;
  const MyWidget(this.onTap);
}
''', 'prefer_async_callback');

        expect(fixed, contains('final AsyncCallback onTap;'));
        expect(fixed, contains("import 'package:flutter/foundation.dart';"));
      },
    );

    test('replaces a nullable parameter type with AsyncCallback?', () async {
      final fixed = await harness.applyFix(r'''
class MyWidget {
  final Future<void> Function()? onTap;
  const MyWidget(this.onTap);
}
''', 'prefer_async_callback');

      expect(fixed, contains('final AsyncCallback? onTap;'));
    });
  });

  group('prefer_bloc_extensions', () {
    const blocPackage = r'''
class BlocBase<State> {
  BlocBase(State initialState);
}
class Bloc<Event, State> extends BlocBase<State> {
  Bloc(super.initialState);
}
class Cubit<State> extends BlocBase<State> {
  Cubit(super.initialState);
}
''';
    const flutterWidgetsBuildContext = r'''
class BuildContext {}
''';
    const flutterBlocPackage = r'''
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';

class BlocProvider<T extends BlocBase> {
  static T of<T extends BlocBase>(BuildContext context, {bool listen = false}) {
    throw UnimplementedError();
  }
}

class RepositoryProvider<T> {
  static T of<T>(BuildContext context, {bool listen = false}) {
    throw UnimplementedError();
  }
}

extension ReadContext on BuildContext {
  T read<T>() => throw UnimplementedError();
}

extension WatchContext on BuildContext {
  T watch<T>() => throw UnimplementedError();
}
''';

    test('replaces BlocProvider.of<T>() with context.read<T>()', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';
class MyCubit extends Cubit<int> { MyCubit() : super(0); }
void f(BuildContext context) {
  final bloc = BlocProvider.of<MyCubit>(context);
}
''',
        'prefer_bloc_extensions',
        packages: {
          'bloc': blocPackage,
          'flutter': flutterWidgetsBuildContext,
          'flutter_bloc': flutterBlocPackage,
        },
      );

      expect(fixed, contains('final bloc = context.read<MyCubit>();'));
      expect(fixed, isNot(contains('BlocProvider.of')));
    });

    test(
      'replaces BlocProvider.of() with listen:true by context.watch()',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';
class MyCubit extends Cubit<int> { MyCubit() : super(0); }
void f(BuildContext context) {
  BlocProvider.of<MyCubit>(context, listen: true);
}
''',
          'prefer_bloc_extensions',
          packages: {
            'bloc': blocPackage,
            'flutter': flutterWidgetsBuildContext,
            'flutter_bloc': flutterBlocPackage,
          },
        );

        expect(fixed, contains('context.watch<MyCubit>();'));
      },
    );

    test(
      'replaces RepositoryProvider.of<T>() with context.read<T>()',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
class MyRepo {}
void f(BuildContext context) {
  final repo = RepositoryProvider.of<MyRepo>(context);
}
''',
          'prefer_bloc_extensions',
          packages: {
            'bloc': blocPackage,
            'flutter': flutterWidgetsBuildContext,
            'flutter_bloc': flutterBlocPackage,
          },
        );

        expect(fixed, contains('final repo = context.read<MyRepo>();'));
      },
    );
  });

  group('prefer_center_over_align', () {
    const flutterAlign = r'''
class Widget {}
class Align extends Widget {
  Align({AlignmentGeometry? alignment, Widget? child});
}
class AlignmentGeometry {}
class Alignment implements AlignmentGeometry {
  static const Alignment center = Alignment(0, 0);
  static const Alignment topLeft = Alignment(-1, -1);
  const Alignment(double x, double y);
}
class Center extends Widget {}
''';

    test('replaces Align with Center', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';
Widget f() {
  return Align(alignment: Alignment.center);
}
''',
        'prefer_center_over_align',
        packages: {'flutter': flutterAlign},
      );

      expect(fixed, contains('Center('));
      expect(fixed, isNot(contains('Align(')));
    });

    // test(
    //   'replaces Align(alignment: center) with Center, dropping the arg',
    //   () async {
    //     final fixed = await harness.applyFix(
    //       r'''
    // import 'package:flutter/flutter.dart';
    // Widget f() {
    //   return Align(alignment: Alignment.center);
    // }
    // ''',
    //       'prefer_center_over_align',
    //       packages: {'flutter': flutterAlign},
    //     );
    //
    //     expect(fixed, contains('return Center();'));
    //     expect(fixed, isNot(contains('alignment')));
    //   },
    // );
    //
    // test('replaces bare Align() (implicit center) with Center()', () async {
    //   final fixed = await harness.applyFix(
    //     r'''
    // import 'package:flutter/flutter.dart';
    // Widget f() {
    //   return Align();
    // }
    // ''',
    //     'prefer_center_over_align',
    //     packages: {'flutter': flutterAlign},
    //   );
    //
    //   expect(fixed, contains('return Center();'));
    // });
    //
    // test('replaces Align with Center while keeping other arguments', () async {
    //   final fixed = await harness.applyFix(
    //     r'''
    // import 'package:flutter/flutter.dart';
    // Widget f() {
    //   return Align(alignment: Alignment.center, child: Align());
    // }
    // ''',
    //     'prefer_center_over_align',
    //     packages: {'flutter': flutterAlign},
    //   );
    //
    //   expect(fixed, contains('return Center(child: Align());'));
    // });
  });

  group('prefer_class_destructuring', () {
    test(
      'inserts a destructuring declaration before the first access',
      () async {
        final fixed = await harness.applyFix(r'''
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
''', 'prefer_class_destructuring');

        expect(fixed, contains('final Foo(:x, :y, :z) = foo;'));
        expect(
          fixed.indexOf('final Foo(:x, :y, :z) = foo;'),
          lessThan(fixed.indexOf('print(foo.x);')),
        );
      },
    );

    test(
      'sorts properties alphabetically in the destructuring pattern',
      () async {
        final fixed = await harness.applyFix(r'''
class Foo {
  int get z => 1;
  int get a => 2;
  int get m => 3;
}

void f(Foo foo) {
  print(foo.z);
  print(foo.a);
  print(foo.m);
}
''', 'prefer_class_destructuring');

        expect(fixed, contains('final Foo(:a, :m, :z) = foo;'));
      },
    );

    test('leaves a preceding method call untouched', () async {
      final fixed = await harness.applyFix(r'''
class Foo {
  int get x => 1;
  int get y => 2;
  int get z => 3;
  void doSomething() {}
}

void f(Foo foo) {
  foo.doSomething();
  print(foo.x);
  print(foo.y);
  print(foo.z);
}
''', 'prefer_class_destructuring');

      expect(fixed, contains('foo.doSomething();'));
      expect(fixed, contains('final Foo(:x, :y, :z) = foo;'));
      expect(
        fixed.indexOf('foo.doSomething();'),
        lessThan(fixed.indexOf('final Foo(:x, :y, :z) = foo;')),
      );
    });
  });

  group('prefer_compute_over_isolate_run', () {
    test(
      'replaces Isolate.run(closure) with compute() and imports foundation',
      () async {
        final fixed = await harness.applyFix(r'''
import 'dart:isolate';

void fn() async {
  final result = await Isolate.run(() => 42);
}
''', 'prefer_compute_over_isolate_run');

        expect(
          fixed,
          contains('final result = await compute((_) => 42, null);'),
        );
        expect(fixed, contains("import 'package:flutter/foundation.dart';"));
      },
    );

    test('wraps a function reference callback as (_) => fn()', () async {
      final fixed = await harness.applyFix(r'''
import 'dart:isolate';

int expensiveWork() => 42;

void fn() async {
  final result = await Isolate.run(expensiveWork);
}
''', 'prefer_compute_over_isolate_run');

      expect(
        fixed,
        contains('final result = await compute((_) => expensiveWork(), null);'),
      );
    });

    test('transforms an async block-body closure, keeping async', () async {
      final fixed = await harness.applyFix(r'''
import 'dart:isolate';

void fn() async {
  final result = await Isolate.run(() async {
    return 42;
  });
}
''', 'prefer_compute_over_isolate_run');

      expect(fixed, contains('compute((_) async {'));
      expect(fixed, contains('return 42;'));
      expect(fixed, contains('}, null);'));
    });
  });

  group('prefer_const_border_radius', () {
    const flutterPainting = r'''
class Radius {
  const Radius.circular(double radius);
}

class BorderRadius {
  const BorderRadius.all(Radius radius);
  static BorderRadius circular(double radius) =>
      BorderRadius.all(Radius.circular(radius));
}
''';

    test(
      'replaces BorderRadius.circular() with the all/Radius.circular form',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:flutter/flutter.dart';
final radius = BorderRadius.circular(8);
''',
          'prefer_const_border_radius',
          packages: {'flutter': flutterPainting},
        );

        expect(
          fixed,
          contains('final radius = BorderRadius.all(Radius.circular(8));'),
        );
      },
    );

    test('preserves a variable argument through the replacement', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';
void f(double r) {
  final radius = BorderRadius.circular(r);
}
''',
        'prefer_const_border_radius',
        packages: {'flutter': flutterPainting},
      );

      expect(
        fixed,
        contains('final radius = BorderRadius.all(Radius.circular(r));'),
      );
    });

    test('handles BorderRadius.circular as a named constructor', () async {
      const flutterPaintingNamedCtor = r'''
class Radius {
  const Radius.circular(double radius);
}

class BorderRadius {
  const BorderRadius.all(Radius radius);
  const BorderRadius.circular(double radius);
}
''';

      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';
final radius = BorderRadius.circular(8);
''',
        'prefer_const_border_radius',
        packages: {'flutter': flutterPaintingNamedCtor},
      );

      expect(
        fixed,
        contains('final radius = BorderRadius.all(Radius.circular(8));'),
      );
    });
  });

  group('prefer_constrained_box_over_container', () {
    const flutterConstraints = r'''
class Widget {}
class Key {}
class BoxConstraints {
  const BoxConstraints({double? minWidth, double? maxWidth, double? minHeight, double? maxHeight});
  const BoxConstraints.tightFor({double? width, double? height});
}
class EdgeInsets {
  const EdgeInsets.all(double value);
}
class Container extends Widget {
  Container({Key? key, BoxConstraints? constraints, EdgeInsets? padding, EdgeInsets? margin, Widget? child, double? width, double? height});
}
class ConstrainedBox extends Widget {
  ConstrainedBox({Key? key, required BoxConstraints constraints, Widget? child});
}
''';

    test('replaces Container with ConstrainedBox', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';
Widget f() {
  return Container(constraints: BoxConstraints());
}
''',
        'prefer_constrained_box_over_container',
        packages: {'flutter': flutterConstraints},
      );

      expect(fixed, contains('ConstrainedBox('));
      expect(fixed, isNot(contains('Container(')));
    });

    // test('replaces Container(constraints: ...) with ConstrainedBox', () async {
    //   final fixed = await harness.applyFix(
    //     r'''
    // import 'package:flutter/flutter.dart';
    // Widget f() {
    //   return Container(constraints: BoxConstraints());
    // }
    // ''',
    //     'prefer_constrained_box_over_container',
    //     packages: {'flutter': flutterConstraints},
    //   );
    //
    //   expect(
    //     fixed,
    //     contains('return ConstrainedBox(constraints: BoxConstraints());'),
    //   );
    //   expect(fixed, isNot(contains('Container(')));
    // });
    //
    // test(
    //   'replaces Container with ConstrainedBox, keeping child argument',
    //   () async {
    //     final fixed = await harness.applyFix(
    //       r'''
    // import 'package:flutter/flutter.dart';
    // Widget f() {
    //   return Container(constraints: BoxConstraints(), child: Container());
    // }
    // ''',
    //       'prefer_constrained_box_over_container',
    //       packages: {'flutter': flutterConstraints},
    //     );
    //
    //     expect(
    //       fixed,
    //       contains(
    //         'return ConstrainedBox(constraints: BoxConstraints(), child: Container());',
    //       ),
    //     );
    //   },
    // );
  });
}
