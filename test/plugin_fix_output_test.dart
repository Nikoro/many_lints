import 'package:test/test.dart';

import 'fix_harness.dart';
import 'fpdart_stub.dart';

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

  group('prefer_and_then', () {
    test('rewrites a bare call to a tear-off', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:fpdart/fpdart.dart';

class Repo {
  TaskEither<String, int> logout() => throw UnimplementedError();
}

TaskEither<String, int> f(TaskEither<String, String> p, Repo repo) =>
    p.flatMap((_) => repo.logout());
''',
        'prefer_and_then',
        multiFilePackages: {'fpdart': fpdartStubFiles},
      );

      expect(fixed, contains('p.andThen(repo.logout)'));
      expect(fixed, isNot(contains('flatMap')));
    });

    test('keeps a thunk when the call takes arguments', () async {
      final fixed = await harness.applyFix(
        r'''
import 'package:fpdart/fpdart.dart';

TaskEither<String, int> seed(int count) => throw UnimplementedError();

TaskEither<String, int> f(TaskEither<String, String> p) =>
    p.flatMap((_) => seed(3));
''',
        'prefer_and_then',
        multiFilePackages: {'fpdart': fpdartStubFiles},
      );

      expect(fixed, contains('p.andThen(() => seed(3))'));
    });
  });

  group('match_pattern', () {
    const unawaitedConfig = '''
rules:
  match_pattern:
    patterns:
      - find: '^unawaited\\((.+)\\)\$'
        replace: '\$1.unawaited()'
        message: 'Prefer the trailing form.'
''';

    test('applies the configured replacement', () async {
      final fixed = await harness.applyFix(
        r'''
void unawaited(Object? f) {}

void run() {
  unawaited(refresh());
}

Object? refresh() => null;
''',
        'match_pattern',
        manyLintsConfig: unawaitedConfig,
      );

      expect(fixed, contains('refresh().unawaited();'));
      expect(fixed, isNot(contains('unawaited(refresh())')));
    });

    test('offers nothing when the entry has no replace', () async {
      const reportOnly = '''
rules:
  match_pattern:
    patterns:
      - find: '^unawaited\\((.+)\\)\$'
        message: 'Report only.'
''';

      // The diagnostic still stands; nothing is offered to rewrite it.
      await harness.expectNoFix(
        r'''
void unawaited(Object? f) {}

void run() {
  unawaited(1);
}
''',
        'match_pattern',
        manyLintsConfig: reportOnly,
      );
    });

    test('declines a replacement that would not parse', () async {
      const brokenTemplate = '''
rules:
  match_pattern:
    patterns:
      - find: '^unawaited\\((.+)\\)\$'
        replace: '\$1.unawaited((('
''';

      // A wrong pattern must not turn working code into a syntax error.
      await harness.expectNoFix(
        r'''
void unawaited(Object? f) {}

void run() {
  unawaited(1);
}
''',
        'match_pattern',
        manyLintsConfig: brokenTemplate,
      );
    });
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
