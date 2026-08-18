import 'package:many_lints/src/rules/avoid_dst_unsafe_date_arithmetic.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(AvoidDstUnsafeDateArithmeticTest),
  );
}

@reflectiveTest
class AvoidDstUnsafeDateArithmeticTest extends ManyLintsRuleTest {
  @override
  void setUp() {
    rule = AvoidDstUnsafeDateArithmetic();
    super.setUp();
    _extendMockDateTime();
  }

  /// analyzer_testing's trimmed `dart:core` declares a `DateTime` with only
  /// `now`, `compareTo`, `isBefore` and `millisecondsSinceEpoch`. Extend that
  /// mock rather than weakening the rule's resolved-type check — without the
  /// members the rule matches on, every negative assertion here would pass
  /// vacuously against an unresolved receiver.
  void _extendMockDateTime() {
    final corePath = '$sdkRoot/lib/core/core.dart';
    final coreSource = getFile(corePath).readAsStringSync();
    newFile(
      corePath,
      coreSource.replaceFirst(
        '  external int get millisecondsSinceEpoch;\n}',
        '''
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
}''',
      ),
    );
  }

  Future<void> test_addDays() async {
    await assertDiagnostics(
      r'''
void f(DateTime d) {
  d.add(const Duration(days: 1));
}
''',
      [lint(23, 30)],
    );
  }

  Future<void> test_subtractDays() async {
    await assertDiagnostics(
      r'''
void f(DateTime d) {
  d.subtract(const Duration(days: 7));
}
''',
      [lint(23, 35)],
    );
  }

  Future<void> test_addDays_nonConstDuration() async {
    await assertDiagnostics(
      r'''
void f(DateTime d) {
  d.add(Duration(days: 1));
}
''',
      [lint(23, 24)],
    );
  }

  Future<void> test_addWholeDayInHours() async {
    await assertDiagnostics(
      r'''
void f(DateTime d) {
  d.add(const Duration(hours: 48));
}
''',
      [lint(23, 32)],
    );
  }

  Future<void> test_addDays_onConstructedLocalDateTime() async {
    await assertDiagnostics(
      r'''
void f() {
  DateTime(2025, 3, 30).add(const Duration(days: 1));
}
''',
      [lint(13, 50)],
    );
  }

  Future<void> test_addDays_onLocalVariable() async {
    await assertDiagnostics(
      r'''
void f() {
  final d = DateTime.now();
  d.add(const Duration(days: 1));
}
''',
      [lint(41, 30)],
    );
  }

  Future<void> test_addHours_isNotReported() async {
    await assertNoDiagnostics(r'''
void f(DateTime d) {
  d.add(const Duration(hours: 2));
}
''');
  }

  Future<void> test_addMinutes_isNotReported() async {
    await assertNoDiagnostics(r'''
void f(DateTime d) {
  d.subtract(const Duration(minutes: 30));
}
''');
  }

  Future<void> test_mixedDayAndSubDayComponents_isNotReported() async {
    await assertNoDiagnostics(r'''
void f(DateTime d) {
  d.add(const Duration(days: 1, hours: 2));
}
''');
  }

  Future<void> test_hoursNotWholeDays_isNotReported() async {
    await assertNoDiagnostics(r'''
void f(DateTime d) {
  d.add(const Duration(hours: 25));
}
''');
  }

  Future<void> test_utcConstructor_isNotReported() async {
    await assertNoDiagnostics(r'''
void f() {
  DateTime.utc(2025, 3, 30).add(const Duration(days: 1));
}
''');
  }

  Future<void> test_toUtc_isNotReported() async {
    await assertNoDiagnostics(r'''
void f(DateTime d) {
  d.toUtc().add(const Duration(days: 1));
}
''');
  }

  Future<void> test_utcLocalVariable_isNotReported() async {
    await assertNoDiagnostics(r'''
void f() {
  final d = DateTime.utc(2025, 3, 30);
  d.add(const Duration(days: 1));
}
''');
  }

  Future<void> test_chainedShiftOnUtc_isNotReported() async {
    await assertNoDiagnostics(r'''
void f() {
  DateTime.utc(2025, 3, 30)
      .add(const Duration(days: 1))
      .add(const Duration(days: 1));
}
''');
  }

  Future<void> test_nonDateTimeReceiver_isNotReported() async {
    await assertNoDiagnostics(r'''
class Schedule {
  void add(Duration duration) {}
}

void f(Schedule s) {
  s.add(const Duration(days: 1));
}
''');
  }

  Future<void> test_zeroDays_isNotReported() async {
    await assertNoDiagnostics(r'''
void f(DateTime d) {
  d.add(const Duration(days: 0));
}
''');
  }
}
