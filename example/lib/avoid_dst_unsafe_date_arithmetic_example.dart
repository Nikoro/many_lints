// ignore_for_file: unused_local_variable
// ignore_for_file: many_lints/prefer_class_destructuring

// avoid_dst_unsafe_date_arithmetic
//
// Warns when whole days are added to or subtracted from a local DateTime with
// a Duration. Duration is absolute elapsed time, but a calendar day is 23 or
// 25 hours long on the two days a year a DST transition happens, so the result
// lands on the wrong wall-clock time.

// ❌ Bad: absolute arithmetic used for calendar shifts
void badDayArithmetic(DateTime today) {
  // LINT: in Europe/Warsaw, 2025-03-29 12:00 + 1 day == 2025-03-30 13:00
  final tomorrow = today.add(const Duration(days: 1));

  // LINT: the same defect on the way back
  final yesterday = today.subtract(const Duration(days: 1));

  // LINT: a week filter that is an hour short twice a year
  final weekAgo = today.subtract(const Duration(days: 7));

  // LINT: whole days written as hours is the same bug
  final inTwoDays = today.add(const Duration(hours: 48));
}

void badStartOfDay() {
  // LINT: midnight stops being midnight across a spring-forward transition
  final nextMidnight = DateTime(2025, 3, 30).add(const Duration(days: 1));
}

// ✅ Good: the constructor normalises against the calendar
void goodDayArithmetic(DateTime today) {
  final tomorrow = DateTime(
    today.year,
    today.month,
    today.day + 1,
    today.hour,
    today.minute,
  );

  // Rollover is handled: day 0 lands on the last day of the previous month
  final yesterday = DateTime(
    today.year,
    today.month,
    today.day - 1,
    today.hour,
    today.minute,
  );
}

// ✅ Good: UTC has no transitions, so Duration arithmetic is exact there
void goodUtcArithmetic(DateTime today) {
  final weekAgo = today.toUtc().subtract(const Duration(days: 7));
  final tomorrow = DateTime.utc(2025, 3, 30).add(const Duration(days: 1));
}

// ✅ Edge case: sub-day durations are genuinely absolute and never reported
void elapsedTimeIsFine(DateTime start) {
  final timeout = start.add(const Duration(hours: 2));
  final retryAt = start.add(const Duration(minutes: 30));

  // Not a whole number of days, so not calendar arithmetic
  final oddSpan = start.add(const Duration(hours: 25));

  // A mixed duration carries a sub-day component the day field cannot express
  final mixed = start.add(const Duration(days: 1, hours: 2));
}
