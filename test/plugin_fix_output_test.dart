import 'package:test/test.dart';

import 'fix_harness.dart';

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

  group('prefer_add_all', () {
    test('rewrites an add-only loop', () async {
      final fixed = await harness.applyFix(r'''
void copy(List<int> target, List<int> source) {
  for (final item in source) {
    target.add(item);
  }
}
''', 'prefer_add_all');

      expect(fixed, contains('target.addAll(source);'));
      expect(fixed, isNot(contains('for (')));
    });

    test('collapses two consecutive add calls', () async {
      final fixed = await harness.applyFix(r'''
void fill(List<String> values) {
  values.add('first');
  values.add('second');
}
''', 'prefer_add_all');

      expect(fixed, contains("values.addAll(['first', 'second']);"));
      expect(fixed, isNot(contains("values.add('first');")));
    });

    test('collapses a run of three add calls', () async {
      final fixed = await harness.applyFix(r'''
void fill(List<String> values) {
  values.add('a');
  values.add('b');
  values.add('c');
}
''', 'prefer_add_all');

      expect(fixed, contains("values.addAll(['a', 'b', 'c']);"));
    });

    test('leaves statements outside the run untouched', () async {
      final fixed = await harness.applyFix(r'''
void fill(List<String> values) {
  print('before');
  values.add('a');
  values.add('b');
  print('after');
}
''', 'prefer_add_all');

      expect(fixed, contains("values.addAll(['a', 'b']);"));
      expect(fixed, contains("print('before');"));
      expect(fixed, contains("print('after');"));
    });
  });

  group('avoid_duplicate_collection_elements', () {
    test('removes a duplicated value', () async {
      final fixed = await harness.applyFix(r'''
final values = [1, 2, 1];
''', 'avoid_duplicate_collection_elements');

      expect(fixed, contains('[1, 2]'));
    });

    test('removes a duplicated spread', () async {
      final fixed = await harness.applyFix(r'''
final base = [1, 2];
final values = [...base, ...base];
''', 'avoid_duplicate_collection_elements');

      expect(fixed, contains('[...base]'));
    });

    test('removes a duplicated if element', () async {
      final fixed = await harness.applyFix(r'''
List<String> build(List<int> items) => [
  if (items.isNotEmpty) 'value',
  if (items.isNotEmpty) 'value',
];
''', 'avoid_duplicate_collection_elements');

      expect(
        RegExp(r"if \(items\.isNotEmpty\)").allMatches(fixed),
        hasLength(1),
      );
    });
  });

  group('avoid_shrink_wrap_in_lists', () {
    test('drops shrinkWrap and keeps the other arguments', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';

Widget build() => ListView(
  shrinkWrap: true,
  children: const [Text('a')],
);
''',
        'avoid_shrink_wrap_in_lists',
        packages: {'flutter': flutterWidgets},
      );

      expect(fixed, isNot(contains('shrinkWrap')));
      expect(fixed, contains("children: const [Text('a')]"));
    });

    test('drops shrinkWrap when it is the only argument', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:flutter/flutter.dart';

Widget build() => ListView(shrinkWrap: true);
''',
        'avoid_shrink_wrap_in_lists',
        packages: {'flutter': flutterWidgets},
      );

      expect(fixed, isNot(contains('shrinkWrap')));
      expect(fixed, contains('ListView()'));
    });
  });

  group('avoid_unnecessary_negations', () {
    test('collapses a double negation', () async {
      final fixed = await harness.applyFix(r'''
bool check(bool flag) => !!flag;
''', 'avoid_unnecessary_negations');

      expect(fixed, contains('=> flag;'));
    });

    test('rewrites a negated inequality', () async {
      final fixed = await harness.applyFix(r'''
bool check(int a, int b) => !(a != b);
''', 'avoid_unnecessary_negations');

      expect(fixed, contains('=> a == b;'));
    });

    test('replaces a negated boolean literal', () async {
      final fixed = await harness.applyFix(r'''
bool check() => !true;
''', 'avoid_unnecessary_negations');

      expect(fixed, contains('=> false;'));
    });

    test('drops negations from both sides of an equality', () async {
      final fixed = await harness.applyFix(r'''
bool check(bool a, bool b) => !a == !b;
''', 'avoid_unnecessary_negations');

      expect(fixed, contains('=> a == b;'));
    });

    test('drops negations from both sides of an inequality', () async {
      final fixed = await harness.applyFix(r'''
bool check(bool a, bool b) => !a != !b;
''', 'avoid_unnecessary_negations');

      expect(fixed, contains('=> a != b;'));
    });
  });
}
