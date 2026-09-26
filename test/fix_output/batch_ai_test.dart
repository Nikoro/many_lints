import 'package:test/test.dart';

import '../fix_harness.dart';

/// End-to-end tests for the text the `prefer_primary_constructors` fix
/// actually produces.
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

  group('prefer_primary_constructors', () {
    test('collapses a two-field class into the `;` form', () async {
      final fixed = await harness.applyFix(r'''
class Point {
  final int x;
  final int y;
  Point(this.x, this.y);
}
''', 'prefer_primary_constructors');

      expect(fixed, contains('class Point(final int x, final int y);'));
      expect(fixed, isNot(contains('{')));
    });

    test(
      'keeps the constructor parameter order, not the field order',
      () async {
        // Reordering would silently break every positional call site.
        final fixed = await harness.applyFix(r'''
class Pair {
  final int first;
  final int second;
  Pair(this.second, this.first);
}
''', 'prefer_primary_constructors');

        expect(
          fixed,
          contains('class Pair(final int second, final int first);'),
        );
      },
    );

    test('moves `const` onto the class header', () async {
      final fixed = await harness.applyFix(r'''
class Point {
  final int x;
  const Point(this.x);
}
''', 'prefer_primary_constructors');

      expect(fixed, contains('class const Point(final int x);'));
    });

    test('preserves named parameters and `required`', () async {
      final fixed = await harness.applyFix(r'''
class Config {
  final int retries;
  final String host;
  Config({required this.retries, required this.host});
}
''', 'prefer_primary_constructors');

      expect(
        fixed,
        contains(
          'class Config({required final int retries, '
          'required final String host});',
        ),
      );
    });

    test('preserves a default value on a named parameter', () async {
      final fixed = await harness.applyFix(r'''
class Config {
  final int retries;
  Config({this.retries = 3});
}
''', 'prefer_primary_constructors');

      expect(fixed, contains('class Config({final int retries = 3});'));
    });

    test('preserves type parameters', () async {
      final fixed = await harness.applyFix(r'''
class Box<T> {
  final T value;
  Box(this.value);
}
''', 'prefer_primary_constructors');

      expect(fixed, contains('class Box<T>(final T value);'));
    });

    test(
      "carries a field's doc comment and annotation into the header",
      () async {
        final fixed = await harness.applyFix(r'''
class Point {
  /// The horizontal offset.
  @deprecated
  final int x;
  Point(this.x);
}
''', 'prefer_primary_constructors');

        expect(
          fixed,
          equals(r'''
class Point(
/// The horizontal offset.
@deprecated final int x);
'''),
        );
      },
    );

    test('keeps methods, getters and other fields in the body', () async {
      final fixed = await harness.applyFix(r'''
class Point {
  static const origin = 0;

  final int x;
  final int y;
  late final int sum = x + y;

  const Point(this.x, this.y);

  int get doubled => x * 2;
}
''', 'prefer_primary_constructors');

      expect(
        fixed,
        equals(r'''
class const Point(final int x, final int y) {
  static const origin = 0;

  late final int sum = x + y;

  int get doubled => x * 2;
}
'''),
      );
    });

    test('keeps the comment of the member after the constructor', () async {
      final fixed = await harness.applyFix(r'''
class Downsizer {
  const Downsizer();

  // Edge case: the server republishes at 256px.
  static const maximumDimension = 512;
}
''', 'prefer_primary_constructors');

      expect(
        fixed,
        equals(r'''
class const Downsizer() {
  // Edge case: the server republishes at 256px.
  static const maximumDimension = 512;
}
'''),
      );
    });

    test("moves a field's leading comment with it", () async {
      final fixed = await harness.applyFix(r'''
class Storage {
  // Edge case: tokens must survive a locked phone.
  final String key;

  Storage(this.key);
}
''', 'prefer_primary_constructors');

      expect(
        fixed,
        equals(r'''
class Storage(
// Edge case: tokens must survive a locked phone.
final String key);
'''),
      );
    });

    test('moves the initializer list and body into a this block', () async {
      final fixed = await harness.applyFix(r'''
class Base(final int id);

class Derived extends Base {
  final int x;
  final int doubled;

  // Edge case: seed must be positive.
  Derived(super.id, this.x, int seed) : doubled = seed * 2, assert(seed > 0) {
    print(x);
  }

  int get y => doubled;
}
''', 'prefer_primary_constructors');

      expect(
        fixed,
        equals(r'''
class Base(final int id);

class Derived(super.id, final int x, int seed) extends Base {
  final int doubled;

  // Edge case: seed must be positive.
  this : doubled = seed * 2, assert(seed > 0) {
    print(x);
  }

  int get y => doubled;
}
'''),
      );
    });

    test('keeps a plain parameter feeding the initializer list', () async {
      final fixed = await harness.applyFix(r'''
class Format {
  final int win;
  final int winAfterDrop;

  const Format({required this.win, int? winAfterDrop}) : winAfterDrop = winAfterDrop ?? win;
}
''', 'prefer_primary_constructors');

      expect(
        fixed,
        equals(r'''
class const Format({required final int win, int? winAfterDrop}) {
  final int winAfterDrop;

  this : winAfterDrop = winAfterDrop ?? win;
}
'''),
      );
    });

    test('declares a mutable field with var', () async {
      final fixed = await harness.applyFix(r'''
class Counter {
  int count;
  Counter(this.count);
}
''', 'prefer_primary_constructors');

      expect(
        fixed,
        equals(r'''
class Counter(var int count);
'''),
      );
    });

    test(
      "keeps a named constructor's name and the other constructors",
      () async {
        final fixed = await harness.applyFix(r'''
class Named {
  final int x;
  Named._(this.x);

  factory Named.parse(String s) => Named._(int.parse(s));
}
''', 'prefer_primary_constructors');

        expect(
          fixed,
          equals(r'''
class Named._(final int x) {
  factory Named.parse(String s) => Named._(int.parse(s));
}
'''),
        );
      },
    );

    test('converts an enum without spelling const', () async {
      final fixed = await harness.applyFix(r'''
enum Color {
  red('#f00'),
  green('#0f0');

  const Color(this.hex);

  final String hex;
}
''', 'prefer_primary_constructors');

      expect(
        fixed,
        equals(r'''
enum Color(final String hex) {
  red('#f00'),
  green('#0f0');
}
'''),
      );
    });
  });
}
