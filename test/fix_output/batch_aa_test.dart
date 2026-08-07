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

  const flutterListenable = r'''
typedef VoidCallback = void Function();

abstract class Listenable {
  void addListener(VoidCallback listener);
  void removeListener(VoidCallback listener);
}

class ChangeNotifier implements Listenable {
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

class ValueNotifier<T> extends ChangeNotifier {
  T value;
  ValueNotifier(this.value);
}

class Widget {}

class StatefulWidget extends Widget {
  State createState() => throw UnimplementedError();
}

abstract class State<T extends StatefulWidget> {
  void initState() {}
  void dispose() {}
  Widget build();
}
''';

  group('always_remove_listener', () {
    test('creates a dispose() method with removeListener', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final ValueNotifier<int> _notifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _notifier.addListener(_onChanged);
  }

  void _onChanged() {}

  @override
  Widget build() => Widget();
}
''',
        'always_remove_listener',
        packages: {'flutter': flutterListenable},
      );

      expect(fixed, contains('void dispose() {'));
      expect(fixed, contains('_notifier.removeListener(_onChanged);'));
    });

    test(
      'inserts removeListener before super.dispose() in existing dispose()',
      () async {
        final fixed = await harness.applyFix(
          r'''
import 'package:flutter/flutter.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final ValueNotifier<int> _notifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _notifier.addListener(_onChanged);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onChanged() {}

  @override
  Widget build() => Widget();
}
''',
          'always_remove_listener',
          packages: {'flutter': flutterListenable},
        );

        final removeIndex = fixed.indexOf(
          '_notifier.removeListener(_onChanged);',
        );
        final superDisposeIndex = fixed.indexOf('super.dispose();');
        expect(removeIndex, greaterThan(-1));
        expect(superDisposeIndex, greaterThan(-1));
        expect(removeIndex, lessThan(superDisposeIndex));
      },
    );
  });

  const riverpodAsyncValue = r'''
class AsyncValue<T> {
  const AsyncValue();
  T? get value => throw UnimplementedError();
  bool get hasValue => throw UnimplementedError();
}

class AsyncData<T> extends AsyncValue<T> {
  const AsyncData();
}

class AsyncLoading<T> extends AsyncValue<T> {
  const AsyncLoading();
}

class AsyncError<T> extends AsyncValue<T> {
  const AsyncError();
}
''';

  group('async_value_nullable_pattern', () {
    test('replaces the null check with an explicit hasValue check', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:riverpod/riverpod.dart';

void fn(AsyncValue<int?> asyncValue) {
  switch (asyncValue) {
    case AsyncValue(:final value?):
      print(value);
    default:
      break;
  }
}
''',
        'async_value_nullable_pattern',
        packages: {'riverpod': riverpodAsyncValue},
      );

      expect(fixed, contains('AsyncValue(:final value, hasValue: true)'));
      expect(fixed, isNot(contains('value?')));
    });

    test('applies the same rewrite for an unbounded generic value', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:riverpod/riverpod.dart';

void fn(AsyncValue<dynamic> asyncValue) {
  switch (asyncValue) {
    case AsyncValue(:final value?):
      print(value);
    default:
      break;
  }
}
''',
        'async_value_nullable_pattern',
        packages: {'riverpod': riverpodAsyncValue},
      );

      expect(fixed, contains('AsyncValue(:final value, hasValue: true)'));
    });
  });

  const flutterBorder = r'''
class Color {
  const Color(int value);
}

enum BorderStyle { none, solid }

class BorderSide {
  const BorderSide({
    Color color = const Color(0xFF000000),
    double width = 1.0,
    BorderStyle style = BorderStyle.solid,
  });
}

class Border {
  const Border({BorderSide side = const BorderSide()});
  const Border.fromBorderSide(BorderSide side);
  factory Border.all({
    Color color = const Color(0xFF000000),
    double width = 1.0,
    BorderStyle style = BorderStyle.solid,
  }) => Border.fromBorderSide(BorderSide(color: color, width: width, style: style));
}
''';

  group('avoid_border_all', () {
    test('rewrites Border.all() with no args', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';
final border = Border.all();
''',
        'avoid_border_all',
        packages: {'flutter': flutterBorder},
      );

      expect(fixed, contains('Border.fromBorderSide(BorderSide())'));
    });

    test('preserves arguments when rewriting Border.all(color: ...)', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';
final border = Border.all(color: Color(0xFF000000));
''',
        'avoid_border_all',
        packages: {'flutter': flutterBorder},
      );

      expect(
        fixed,
        contains('Border.fromBorderSide(BorderSide(color: Color(0xFF000000)))'),
      );
    });
  });

  group('avoid_cascade_after_if_null', () {
    test('wraps the if-null expression in parentheses', () async {
      final fixed = await harness.applyFix(r'''
class Foo { void bar() {} }
void f(Foo? x) {
  x ?? Foo()..bar();
}
''', 'avoid_cascade_after_if_null');

      expect(fixed, contains('(x ?? Foo())..bar();'));
    });

    test('wraps an if-null expression before a property cascade', () async {
      final fixed = await harness.applyFix(r'''
class Foo { int value = 0; }
void f(Foo? x) {
  x ?? Foo()..value = 1;
}
''', 'avoid_cascade_after_if_null');

      expect(fixed, contains('(x ?? Foo())..value = 1;'));
    });
  });

  group('avoid_collapsible_if', () {
    test('merges nested if blocks with &&', () async {
      final fixed = await harness.applyFix(r'''
void check(bool a, bool b) {
  if (a) {
    if (b) {
      print('both');
    }
  }
}
''', 'avoid_collapsible_if');

      expect(fixed, contains('if (a && b) {'));
      expect(fixed, contains("print('both');"));
      expect(fixed, isNot(contains('if (b)')));
    });

    test('merges braceless nested ifs onto one line', () async {
      final fixed = await harness.applyFix(r'''
void check(bool a, bool b) {
  if (a) if (b) print('both');
}
''', 'avoid_collapsible_if');

      expect(fixed, contains("if (a && b) print('both');"));
    });
  });

  group('avoid_commented_out_code', () {
    test('removes a single-line commented-out statement', () async {
      final fixed = await harness.applyFix(r'''
// final x = 42;
void f() {}
''', 'avoid_commented_out_code');

      expect(fixed, isNot(contains('final x = 42')));
      expect(fixed, contains('void f() {}'));
    });

    test('removes a multi-line commented-out block entirely', () async {
      final fixed = await harness.applyFix(r'''
// void apply(String value) {
//   print(value);
// }
void f() {}
''', 'avoid_commented_out_code');

      expect(fixed, isNot(contains('apply')));
      expect(fixed, isNot(contains('print(value)')));
      expect(fixed, contains('void f() {}'));
    });
  });

  group('avoid_duplicate_cascades', () {
    test('removes a duplicated property assignment section', () async {
      final fixed = await harness.applyFix(r'''
class Foo {
  String field = '';
}
void f() {
  Foo()
    ..field = '1'
    ..field = '1';
}
''', 'avoid_duplicate_cascades');

      expect(fixed, contains("..field = '1';"));
      expect(RegExp(r"field = '1'").allMatches(fixed), hasLength(1));
    });

    test('removes a duplicated method call section', () async {
      final fixed = await harness.applyFix(r'''
class Foo {
  void bar() {}
}
void f() {
  Foo()
    ..bar()
    ..bar();
}
''', 'avoid_duplicate_cascades');

      expect(RegExp(r'\.\.bar\(\)').allMatches(fixed), hasLength(1));
    });
  });

  group('avoid_empty_spread', () {
    test('removes an empty list spread', () async {
      final fixed = await harness.applyFix(r'''
List<int> build() {
  return [1, ...[], 2];
}
''', 'avoid_empty_spread');

      expect(fixed, contains('[1, 2]'));
      expect(fixed, isNot(contains('...[]')));
    });

    test('removes an empty typed list spread', () async {
      final fixed = await harness.applyFix(r'''
List<int> build() {
  return [1, ...<int>[]];
}
''', 'avoid_empty_spread');

      expect(fixed, isNot(contains('...<int>[]')));
      expect(fixed, contains('[1]'));
    });
  });

  const flutterExpanded = r'''
class Key {
  const Key(String value);
}

abstract class Widget {
  const Widget({Key? key});
}

class Expanded extends Widget {
  final int flex;
  final Widget child;
  const Expanded({super.key, this.flex = 1, required this.child});
}

class SizedBox extends Widget {
  final double? width;
  final double? height;
  final Widget? child;
  const SizedBox({super.key, this.width, this.height, this.child});
}

class Container extends Widget {
  final double? width;
  final double? height;
  final Widget? child;
  const Container({super.key, this.width, this.height, this.child});
}

class Spacer extends Widget {
  final int flex;
  const Spacer({super.key, this.flex = 1});
}

class Text extends Widget {
  final String data;
  const Text(this.data, {super.key});
}
''';

  group('avoid_expanded_as_spacer', () {
    test('replaces Expanded wrapping an empty SizedBox with Spacer', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';
final widget = Expanded(child: SizedBox());
''',
        'avoid_expanded_as_spacer',
        packages: {'flutter': flutterExpanded},
      );

      expect(fixed, contains('final widget = Spacer();'));
      expect(fixed, isNot(contains('SizedBox')));
    });

    test('preserves flex when replacing with Spacer', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';
final widget = Expanded(flex: 2, child: SizedBox());
''',
        'avoid_expanded_as_spacer',
        packages: {'flutter': flutterExpanded},
      );

      expect(fixed, contains('Spacer(flex: 2)'));
    });

    test('keeps the const keyword when replacing a const Expanded', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';
final widget = const Expanded(child: SizedBox());
''',
        'avoid_expanded_as_spacer',
        packages: {'flutter': flutterExpanded},
      );

      expect(fixed, contains('const Spacer()'));
    });
  });

  group('avoid_generics_shadowing', () {
    test(
      'renames a type parameter that shadows a top-level function param',
      () async {
        final fixed = await harness.applyFix(r'''
class Config {}

void process<Config>(Config c) {}
''', 'avoid_generics_shadowing');

        expect(fixed, contains('void process<T>(T c) {}'));
      },
    );

    test('renames a type parameter that shadows a top-level class', () async {
      // Method-level type parameters attach directly to the
      // MethodDeclaration, so both the declaration and the parameter's
      // usages (here, the return type) get renamed correctly.
      final fixed = await harness.applyFix(r'''
class AnotherClass {}

class SomeClass {
  AnotherClass anotherMethod<AnotherClass>() {
    throw '';
  }
}
''', 'avoid_generics_shadowing');

      expect(fixed, contains('T anotherMethod<T>() {'));
      expect(fixed, isNot(contains('AnotherClass anotherMethod')));
      // The unrelated top-level class must stay untouched.
      expect(fixed, contains('class AnotherClass {}'));
    });

    test('picks a fallback letter when T is already in use', () async {
      final fixed = await harness.applyFix(r'''
class MyModel {}

class SomeClass {
  void method<T, MyModel>(T a, MyModel b) {}
}
''', 'avoid_generics_shadowing');

      expect(fixed, contains('void method<T, R>(T a, R b) {}'));
    });
  });

  group('avoid_incomplete_copy_with', () {
    test('adds a missing named parameter to copyWith', () async {
      final fixed = await harness.applyFix(r'''
class Person {
  const Person({
    required this.name,
    required this.surname,
  });

  final String name;
  final String surname;

  Person copyWith({String? name}) {
    return Person(
      name: name ?? this.name,
      surname: surname,
    );
  }
}
''', 'avoid_incomplete_copy_with');

      expect(fixed, contains('copyWith({String? name, String? surname})'));
    });

    test('wraps parameters in braces when copyWith had none', () async {
      final fixed = await harness.applyFix(r'''
class Item {
  const Item({required this.id});

  final int id;

  Item copyWith() {
    return Item(id: id);
  }
}
''', 'avoid_incomplete_copy_with');

      expect(fixed, contains('copyWith({int? id})'));
    });
  });
}
