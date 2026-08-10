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

  group('prefer_container', () {
    const flutterMock = r'''
class Widget {}
class Key {}
class EdgeInsets {
  const EdgeInsets.all(double value);
}
class Alignment {
  static const Alignment center = Alignment();
  const Alignment();
}
class SizedBox extends Widget {
  SizedBox({Key? key, double? width, double? height, Widget? child});
}
class Padding extends Widget {
  Padding({Key? key, required EdgeInsets padding, Widget? child});
}
class Align extends Widget {
  Align({Key? key, Alignment? alignment, Widget? child});
}
class Text extends Widget {
  Text(String data);
}
''';

    test('merges Padding/Align/SizedBox into a single Container', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';
Widget f() {
  return Padding(
    padding: EdgeInsets.all(8),
    child: Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: 100,
        height: 50,
        child: Text('Hello'),
      ),
    ),
  );
}
''',
        'prefer_container',
        packages: {'flutter': flutterMock},
      );

      expect(fixed, contains('padding: EdgeInsets.all(8)'));
      expect(fixed, contains('alignment: Alignment.center'));
      expect(fixed, contains('width: 100'));
      expect(fixed, contains('height: 50'));
      expect(fixed, contains("child: Text('Hello')"));
      expect(fixed, contains('Container('));
      expect(fixed, isNot(contains('Padding(')));
      expect(fixed, isNot(contains('Align(')));
      expect(fixed, isNot(contains('SizedBox(')));
    });
  });

  group('prefer_correct_edge_insets_constructor', () {
    const painting = r'''
class EdgeInsets {
  const EdgeInsets.fromLTRB(double left, double top, double right, double bottom);
  const EdgeInsets.all(double value);
  const EdgeInsets.only({double left = 0, double top = 0, double right = 0, double bottom = 0});
  const EdgeInsets.symmetric({double horizontal = 0, double vertical = 0});
  static const EdgeInsets zero = EdgeInsets.all(0);
}
''';

    test('collapses fromLTRB with all equal values into .all()', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';
final p = EdgeInsets.fromLTRB(8, 8, 8, 8);
''',
        'prefer_correct_edge_insets_constructor',
        packages: {'flutter': painting},
      );

      expect(fixed, contains('EdgeInsets.all(8)'));
      expect(fixed, isNot(contains('fromLTRB')));
    });

    test('collapses symmetric fromLTRB into .symmetric()', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';
final p = EdgeInsets.fromLTRB(8, 4, 8, 4);
''',
        'prefer_correct_edge_insets_constructor',
        packages: {'flutter': painting},
      );

      expect(
        fixed,
        contains('EdgeInsets.symmetric(horizontal: 8, vertical: 4)'),
      );
    });

    test('collapses .only() with all zero values into .zero', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';
final p = EdgeInsets.only(left: 0, top: 0, right: 0, bottom: 0);
''',
        'prefer_correct_edge_insets_constructor',
        packages: {'flutter': painting},
      );

      expect(fixed, contains('EdgeInsets.zero'));
    });
  });

  group('prefer_enums_by_name', () {
    test(
      'rewrites `firstWhere((e) => e.name == value)` to `.byName()`',
      () async {
        final fixed = await harness.applyFix(r'''
enum Color { red, green, blue }

void f() {
  Color.values.firstWhere((e) => e.name == 'red');
}
''', 'prefer_enums_by_name');

        expect(fixed, contains("Color.values.byName('red');"));
      },
    );

    test('rewrites the reversed comparison `value == e.name`', () async {
      final fixed = await harness.applyFix(r'''
enum Color { red, green, blue }

void f() {
  Color.values.firstWhere((e) => 'red' == e.name);
}
''', 'prefer_enums_by_name');

      expect(fixed, contains("Color.values.byName('red');"));
    });

    test('rewrites a block-bodied callback', () async {
      final fixed = await harness.applyFix(r'''
enum Color { red, green, blue }

void f() {
  Color.values.firstWhere((e) { return e.name == 'red'; });
}
''', 'prefer_enums_by_name');

      expect(fixed, contains("Color.values.byName('red');"));
    });
  });

  group('prefer_equatable_mixin', () {
    const equatable = r'''
abstract class Equatable {
  const Equatable();
  List<Object?> get props;
}

mixin EquatableMixin {
  List<Object?> get props;
}
''';

    test('replaces `extends Equatable` with `with EquatableMixin`', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:equatable/equatable.dart';

class Person extends Equatable {
  const Person(this.name);
  final String name;

  @override
  List<Object?> get props => [name];
}
''',
        'prefer_equatable_mixin',
        packages: {'equatable': equatable},
      );

      expect(fixed, contains('class Person with EquatableMixin {'));
      expect(fixed, isNot(contains('extends Equatable')));
    });

    test('appends EquatableMixin to an existing with-clause', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:equatable/equatable.dart';

mixin Loggable {}

class Person extends Equatable with Loggable {
  const Person(this.name);
  final String name;

  @override
  List<Object?> get props => [name];
}
''',
        'prefer_equatable_mixin',
        packages: {'equatable': equatable},
      );

      expect(fixed, contains('class Person with Loggable, EquatableMixin {'));
      expect(fixed, isNot(contains('extends Equatable')));
    });
  });

  group('prefer_expect_later', () {
    const testApi = r'''
  void expect(dynamic actual, dynamic matcher) {}
  Future<void> expectLater(dynamic actual, dynamic matcher) async {}

  const completion = 1;
  ''';

    test(
      'adds await and renames expect to expectLater for a future value',
      () async {
        final fixed = await harness.applyFix(
          r'''
  import 'package:test_api/test_api.dart';

  void f() {
    expect(Future.value(1), completion);
  }
  ''',
          'prefer_expect_later',
          packages: {'test_api': testApi},
        );

        expect(
          fixed,
          contains('await expectLater(Future.value(1), completion);'),
        );
      },
    );
  });

  group('prefer_explicit_function_type', () {
    test('converts a bare Function field type to void Function()', () async {
      final fixed = await harness.applyFix(r'''
class SomeWidget {
  final Function onTap;

  const SomeWidget(this.onTap);
}
''', 'prefer_explicit_function_type');

      expect(fixed, contains('final void Function() onTap;'));
    });

    test(
      'converts a nullable Function type, keeping the question mark',
      () async {
        final fixed = await harness.applyFix(r'''
class SomeWidget {
  final Function? onTap;

  const SomeWidget(this.onTap);
}
''', 'prefer_explicit_function_type');

        expect(fixed, contains('final void Function()? onTap;'));
      },
    );

    test('converts a bare Function parameter type', () async {
      final fixed = await harness.applyFix(r'''
void foo(Function callback) {}
''', 'prefer_explicit_function_type');

      expect(fixed, contains('void foo(void Function() callback) {}'));
    });
  });

  group('prefer_for_loop_in_children', () {
    test('rewrites `.map().toList()` into a collection-for', () async {
      final fixed = await harness.applyFix(r'''
void f() {
  final list = [1, 2, 3];
  final result = list.map((e) => e.toString()).toList();
}
''', 'prefer_for_loop_in_children');

      expect(fixed, contains('[for (final e in list) e.toString()]'));
      expect(fixed, isNot(contains('.map(')));
    });

    test('rewrites a spread `.map()` into a for-element', () async {
      final fixed = await harness.applyFix(r'''
void f() {
  final list = [1, 2, 3];
  final result = [...list.map((e) => e.toString())];
}
''', 'prefer_for_loop_in_children');

      expect(fixed, contains('[for (final e in list) e.toString()]'));
      expect(fixed, isNot(contains('...list')));
    });

    test('rewrites `List.generate()` into a counted for-loop', () async {
      final fixed = await harness.applyFix(r'''
void f() {
  final result = List.generate(5, (index) => index * 2);
}
''', 'prefer_for_loop_in_children');

      expect(
        fixed,
        contains('[for (var index = 0; index < 5; index++) index * 2]'),
      );
      expect(fixed, isNot(contains('List.generate')));
    });
  });

  group('prefer_immediate_return', () {
    test(
      'collapses a final-variable-then-return into a direct return',
      () async {
        final fixed = await harness.applyFix(r'''
int compute(int a) {
  final result = a * 2;
  return result;
}
''', 'prefer_immediate_return');

        expect(fixed, contains('return a * 2;'));
        expect(fixed, isNot(contains('final result')));
      },
    );

    test('collapses a typed variable declaration', () async {
      final fixed = await harness.applyFix(r'''
String describe(int a) {
  final String label = 'value: $a';
  return label;
}
''', 'prefer_immediate_return');

      expect(fixed, contains(r"return 'value: $a';"));
      expect(fixed, isNot(contains('label')));
    });
  });

  group('prefer_immutable_bloc_state', () {
    const blocMetaPackages = {
      'bloc': r'''
  class Bloc<Event, State> {}
  class Cubit<State> {}
  ''',
      'meta': r'''
  class Immutable {
    const Immutable();
  }

  const Immutable immutable = Immutable();
  ''',
    };

    test('adds @immutable and imports package:meta to a state class', () async {
      final fixed = await harness.applyFix(
        r'''
  class MyFeatureState {}
  ''',
        'prefer_immutable_bloc_state',
        packages: blocMetaPackages,
      );

      expect(fixed, contains("import 'package:meta/meta.dart';"));
      expect(fixed, contains('@immutable\nclass MyFeatureState {}'));
    });
  });

  group('prefer_iterable_of', () {
    test('replaces List.from() with List.of()', () async {
      final fixed = await harness.applyFix(r'''
void f() {
  final intList = [1, 2, 3];
  final copy = List<int>.from(intList);
}
''', 'prefer_iterable_of');

      expect(fixed, contains('List<int>.of(intList)'));
      expect(fixed, isNot(contains('.from(')));
    });

    test(
      'replaces Set.from() with Set.of() without explicit type args',
      () async {
        final fixed = await harness.applyFix(r'''
void f() {
  final intSet = <int>{1, 2, 3};
  final copy = Set.from(intSet);
}
''', 'prefer_iterable_of');

        expect(fixed, contains('Set.of(intSet)'));
        expect(fixed, isNot(contains('.from(')));
      },
    );

    test(
      'replaces List.from() invoked via MethodInvocation with extra args',
      () async {
        final fixed = await harness.applyFix(r'''
void f() {
  final intList = [1, 2, 3];
  final copy = List<int>.from(intList, growable: false);
}
''', 'prefer_iterable_of');

        expect(fixed, contains('List<int>.of(intList, growable: false)'));
      },
    );
  });
}
