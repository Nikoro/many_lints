import 'package:test/test.dart';

import '../fix_harness.dart';

void main() {
  late FixHarness harness;

  setUp(() async {
    harness = FixHarness();
    await harness.setUp();
  });

  tearDown(() async {
    await harness.tearDown();
  });

  group('prefer_correct_future_return_type', () {
    test('wraps a broad return type in Future', () async {
      final fixed = await harness.applyFix(
        'Object load() async => 1;',
        'prefer_correct_future_return_type',
      );

      expect(fixed, 'Future<Object> load() async => 1;');
    });

    test('replaces FutureOr with Future', () async {
      final fixed = await harness.applyFix(
        "import 'dart:async';\nFutureOr<int> load() async => 1;",
        'prefer_correct_future_return_type',
      );

      expect(fixed, "import 'dart:async';\nFuture<int> load() async => 1;");
    });

    test('removes Future nullability', () async {
      final fixed = await harness.applyFix(
        'Future<int>? load() async => 1;',
        'prefer_correct_future_return_type',
      );

      expect(fixed, 'Future<int> load() async => 1;');
    });

    test('removes nullable FutureOr nullability', () async {
      final fixed = await harness.applyFix(
        "import 'dart:async';\nFutureOr<int>? load() async => 1;",
        'prefer_correct_future_return_type',
      );

      expect(fixed, "import 'dart:async';\nFuture<int> load() async => 1;");
    });
  });
}
