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

  group('double_literal_format', () {
    test('adds a missing leading zero', () async {
      final fixed = await harness.applyFix(r'''
const x = .5;
''', 'double_literal_format');

      expect(fixed, contains('const x = 0.5;'));
    });

    test('strips a redundant trailing zero', () async {
      final fixed = await harness.applyFix(r'''
const x = 0.50;
''', 'double_literal_format');

      expect(fixed, contains('const x = 0.5;'));
    });

    test('strips redundant leading zeros', () async {
      final fixed = await harness.applyFix(r'''
const x = 00.5;
''', 'double_literal_format');

      expect(fixed, contains('const x = 0.5;'));
    });

    test('keeps the exponent when reformatting the mantissa', () async {
      final fixed = await harness.applyFix(r'''
const x = 1.50e10;
''', 'double_literal_format');

      expect(fixed, contains('const x = 1.5e10;'));
    });
  });

  group('avoid_inconsistent_digit_separators', () {
    test('regroups a decimal literal into threes', () async {
      final fixed = await harness.applyFix(r'''
const x = 10_00_000;
''', 'avoid_inconsistent_digit_separators');

      expect(fixed, contains('const x = 1_000_000;'));
    });

    test('regroups when the leading group was too long', () async {
      final fixed = await harness.applyFix(r'''
const x = 1000_000;
''', 'avoid_inconsistent_digit_separators');

      expect(fixed, contains('const x = 1_000_000;'));
    });

    test('regroups a hex literal into fours', () async {
      final fixed = await harness.applyFix(r'''
const x = 0xFF_FFF_FFF;
''', 'avoid_inconsistent_digit_separators');

      expect(fixed, contains('const x = 0xFFFF_FFFF;'));
    });

    test('honours a configured group size', () async {
      final fixed = await harness.applyFix(
        r'''
const x = 10_00_0000;
''',
        'avoid_inconsistent_digit_separators',
        manyLintsConfig:
            'rules:\n'
            '  avoid_inconsistent_digit_separators:\n'
            '    group_size: 4\n',
      );

      expect(fixed, contains('const x = 1000_0000;'));
    });
  });

  group('prefer_early_return', () {
    test('inverts the condition and de-indents the body', () async {
      final fixed = await harness.applyFix(r'''
void f(bool ok) {
  if (ok) {
    print(1);
    print(2);
    print(3);
  }
}
''', 'prefer_early_return');

      expect(fixed, contains('if (!ok) return;'));
      // The body must come out one level shallower, still inside the function.
      expect(fixed, contains('\n  print(1);'));
      expect(fixed, isNot(contains('    print(1);')));
    });

    test('inverts a comparison into its opposite operator', () async {
      final fixed = await harness.applyFix(r'''
void f(int n) {
  if (n > 0) {
    print(1);
    print(2);
    print(3);
  }
}
''', 'prefer_early_return');

      expect(fixed, contains('if (n <= 0) return;'));
    });

    test('preserves relative indentation inside a nested statement', () async {
      final fixed = await harness.applyFix(r'''
void f(bool ok) {
  if (ok) {
    print(1);
    for (final x in [1]) {
      print(x);
    }
    print(3);
  }
}
''', 'prefer_early_return');

      expect(fixed, contains('if (!ok) return;'));
      expect(fixed, contains('  for (final x in [1]) {'));
      expect(fixed, contains('    print(x);'));
    });
  });

  group('avoid_negated_conditions', () {
    test('inverts the condition and swaps the branches', () async {
      final fixed = await harness.applyFix(r'''
void f(bool ok) {
  if (!ok) {
    print(1);
  } else {
    print(2);
  }
}
''', 'avoid_negated_conditions');

      expect(fixed, contains('if (ok) {'));
      // The branches must have traded places, not just the condition flipped.
      final thenIndex = fixed.indexOf('print(2);');
      final elseIndex = fixed.indexOf('print(1);');
      expect(thenIndex, lessThan(elseIndex));
    });

    test('swaps the two arms of a conditional expression', () async {
      final fixed = await harness.applyFix(r'''
String f(bool isReady) => !isReady ? 'Waiting' : 'Ready';
''', 'avoid_negated_conditions');

      expect(fixed, contains("isReady ? 'Ready' : 'Waiting'"));
    });
  });
}
