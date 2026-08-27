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

  /// The Duration need not be written at the call site. Hiding a
  /// `Duration(days: 30)` behind a getter is the same defect, and is how it
  /// escaped this rule in a real codebase: a notification lead time
  /// subtracted from an event date shifted every reminder that straddled a
  /// DST boundary by an hour.
  Future<void> test_subtractDays_fromGetter() async {
    await assertDiagnostics(
      r'''
class LeadTime {
  Duration get offset => const Duration(days: 30);
}

void f(DateTime d, LeadTime lt) {
  d.subtract(lt.offset);
}
''',
      [lint(107, 21)],
    );
  }

  Future<void> test_addDays_fromLocalVariable() async {
    await assertDiagnostics(
      r'''
void f(DateTime d) {
  final offset = const Duration(days: 7);
  d.add(offset);
}
''',
      [lint(65, 13)],
    );
  }

  Future<void> test_subtractDays_fromStaticConstField() async {
    await assertDiagnostics(
      r'''
class Policy {
  static const Duration retention = Duration(days: 30);
}

void f(DateTime d) {
  d.subtract(Policy.retention);
}
''',
      [lint(97, 28)],
    );
  }

  /// The counterweight to the three above: a named duration that is genuinely
  /// absolute must stay silent, or every timeout and backoff in a codebase
  /// reports and buries the calendar bug in noise.
  Future<void> test_subDayDurationBehindAName_isNotReported() async {
    await assertNoDiagnostics(r'''
class Policy {
  static const Duration cooldown = Duration(minutes: 15);
  Duration get bounce => const Duration(hours: 1);
}

void f(DateTime d, Policy p) {
  d.subtract(Policy.cooldown);
  d.add(p.bounce);
}
''');
  }

  /// A duration this rule cannot resolve — a parameter, a computed value —
  /// stays silent rather than guessing.
  Future<void> test_unresolvableDuration_isNotReported() async {
    await assertNoDiagnostics(r'''
void f(DateTime d, Duration span) {
  d.add(span);
}
''');
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
