import 'package:test/test.dart';

import '../fix_harness.dart';

void main() {
  late FixHarness harness;

  setUp(() async {
    harness = FixHarness();
    await harness.setUp();
    _extendMockDateTime(harness);
  });

  tearDown(() async {
    await harness.tearDown();
  });

  group('avoid_dst_unsafe_date_arithmetic', () {
    test('rewrites an added day onto the DateTime constructor', () async {
      final fixed = await harness.applyFix(r'''
void f(DateTime d) {
  d.add(const Duration(days: 1));
}
''', 'avoid_dst_unsafe_date_arithmetic');

      expect(
        fixed,
        contains(
          'DateTime(d.year, d.month, d.day + 1, d.hour, d.minute, '
          'd.second, d.millisecond, d.microsecond)',
        ),
      );
    });

    test('flips the operator for a subtraction', () async {
      final fixed = await harness.applyFix(r'''
void f(DateTime d) {
  d.subtract(const Duration(days: 7));
}
''', 'avoid_dst_unsafe_date_arithmetic');

      expect(fixed, contains('d.day - 7'));
    });

    test('folds a whole-day hours literal into the day component', () async {
      final fixed = await harness.applyFix(r'''
void f(DateTime d) {
  d.add(const Duration(hours: 48));
}
''', 'avoid_dst_unsafe_date_arithmetic');

      expect(fixed, contains('d.day + 2'));
    });

    test(
      'offers no fix for a receiver that may have side effects when repeated',
      () {
        expect(
          harness.applyFix(r'''
void f() {
  DateTime.now().add(const Duration(days: 1));
}
''', 'avoid_dst_unsafe_date_arithmetic'),
          throwsA(isA<TestFailure>()),
        );
      },
    );
  });
}

// Edge case: the mock dart:core DateTime has almost no members, so the rule would not resolve
void _extendMockDateTime(FixHarness harness) {
  final corePath = '${harness.sdkRoot}/lib/core/core.dart';
  final coreSource = harness.getFile(corePath).readAsStringSync();
  harness.newFile(
    corePath,
    coreSource.replaceFirst('  external int get millisecondsSinceEpoch;\n}', '''
  external int get millisecondsSinceEpoch;

  external DateTime(int year,
      [int month,
      int day,
      int hour,
      int minute,
      int second,
      int millisecond,
      int microsecond]);

  external DateTime.utc(int year,
      [int month,
      int day,
      int hour,
      int minute,
      int second,
      int millisecond,
      int microsecond]);

  external bool get isUtc;
  external int get year;
  external int get month;
  external int get day;
  external int get hour;
  external int get minute;
  external int get second;
  external int get millisecond;
  external int get microsecond;

  external DateTime add(Duration duration);
  external DateTime subtract(Duration duration);
  external DateTime toUtc();
  external DateTime toLocal();
}'''),
  );
}
