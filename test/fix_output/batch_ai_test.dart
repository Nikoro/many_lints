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

    test('declines when a field carries a doc comment', () async {
      // The comment has no home in a parameter list, so the fix withholds
      // rather than dropping documentation silently.
      await expectLater(
        harness.applyFix(r'''
class Point {
  /// The horizontal offset.
  final int x;
  Point(this.x);
}
''', 'prefer_primary_constructors'),
        throwsA(isA<TestFailure>()),
      );
    });

    test('declines when a field carries an annotation', () async {
      await expectLater(
        harness.applyFix(r'''
class Point {
  @deprecated
  final int x;
  Point(this.x);
}
''', 'prefer_primary_constructors'),
        throwsA(isA<TestFailure>()),
      );
    });
  });
}
