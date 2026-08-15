import 'package:test/test.dart';

import '../fix_harness.dart';

/// End-to-end tests for the text the `avoid_unnecessary_continue` fix
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

  group('avoid_unnecessary_continue', () {
    test('removes a trailing continue from a loop body', () async {
      final fixed = await harness.applyFix(r'''
void f(List<int> xs) {
  for (final x in xs) {
    print(x);
    continue;
  }
}
''', 'avoid_unnecessary_continue');

      expect(fixed, isNot(contains('continue')));
      expect(fixed, contains('print(x);'));
    });

    test('leaves a valid body when continue was the only statement', () async {
      final fixed = await harness.applyFix(r'''
void f(List<int> xs) {
  for (final x in xs) {
    continue;
  }
}
''', 'avoid_unnecessary_continue');

      expect(fixed, isNot(contains('continue')));
      // The loop must still have a body it can parse.
      expect(fixed, contains('for (final x in xs)'));
    });
  });
}
