---
title: avoid_dst_unsafe_date_arithmetic
description: "Calendar day arithmetic on a local DateTime should not go through Duration"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_dst_unsafe_date_arithmetic
---

<span class="rule-badge rule-badge--version">v1.1.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Code Quality</span>

This rule flags `add` and `subtract` calls that shift a local `DateTime` by a whole number of days using a `Duration` — `d.add(const Duration(days: 1))`, and the same duration reached through a name.

`Duration` measures *absolute elapsed time*. A calendar day is not always 24 hours long: in any zone that observes daylight saving time, one day each year is 23 hours and another is 25. In `Europe/Warsaw`:

```dart
DateTime(2025, 3, 30).add(const Duration(days: 1));
// 2025-03-31 01:00 — midnight is no longer midnight
```

"Start of day" is exactly what date arithmetic usually computes, so a boundary that drifts to 01:00 puts events in the wrong bucket and makes a "7 days ago" filter cover 6 days and 23 hours. The bug reproduces on two days of the year and never in UTC, so a CI machine running in UTC is guaranteed to stay green.

This rule is in the **`recommended`** preset and takes no configuration. It ships a quick fix.

**See also:** [`DateTime.add` API docs](https://api.dart.dev/stable/dart-core/DateTime/add.html), which carries this exact caveat.

## Don't

```dart
// Shifts by 24 absolute hours, not by a calendar day.
DateTime nextDue(DateTime today) => today.add(const Duration(days: 1));
```

## Do

Bump the day component. The `DateTime` constructor normalises out-of-range
values against the real calendar, so the wall-clock time survives a transition —
and month and year rollover work for free:

```dart
DateTime nextDue(DateTime today) => DateTime(
  today.year,
  today.month,
  today.day + 1,
  today.hour,
  today.minute,
);
```

The quick fix writes exactly this.

## More examples

### A window that is an hour short twice a year

```dart
// Don't
DateTime windowStart(DateTime now) => now.subtract(const Duration(days: 7));
```

```dart
// Do
DateTime windowStart(DateTime now) => DateTime(
  now.year,
  now.month,
  now.day - 7,
  now.hour,
  now.minute,
);
```

### Whole multiples of 24 hours count too

Spelling a day as hours does not change the semantics, so it is reported the
same way:

```dart
// Don't — 48 hours is two calendar days written the long way.
DateTime inTwoDays(DateTime today) => today.add(const Duration(hours: 48));
```

```dart
// Do
DateTime inTwoDays(DateTime today) => DateTime(
  today.year,
  today.month,
  today.day + 2,
  today.hour,
  today.minute,
);
```

### A named duration is not a defence

This is the shape the defect actually survives review in — the call site reads
like domain language and the `Duration` is somewhere else:

```dart
enum LeadTime {
  oneMonthBefore;

  Duration get offsetFromEvent => const Duration(days: 30);
}

// Don't — reported: the getter is resolved back to its declaration.
DateTime reminderFor(DateTime occurrence, LeadTime leadTime) =>
    occurrence.subtract(leadTime.offsetFromEvent);
```

```dart
// Do — work in UTC, which has no transitions.
DateTime reminderFor(DateTime occurrence) =>
    occurrence.toUtc().subtract(const Duration(days: 30));
```

### Sub-day durations are correct as they are

`Duration(hours: 2)` genuinely means two elapsed hours, and absolute arithmetic
is the right semantics for it:

```dart
// Not reported.
DateTime expiry(DateTime issuedAt) => issuedAt.add(const Duration(hours: 2));

// Not reported either — a sub-day component day arithmetic cannot reproduce.
DateTime odd(DateTime d) => d.add(const Duration(days: 1, hours: 2));
```

### UTC receivers are skipped

```dart
// Not reported — statically evident as UTC.
DateTime tomorrowUtc() => DateTime.utc(2025, 3, 30).add(const Duration(days: 1));

DateTime shift(DateTime d) => d.toUtc().add(const Duration(days: 1));
```

For anything more involved than shifting a day, use
[`package:timezone`](https://pub.dev/packages/timezone), which models real zone
rules.

## Known limitations

**A named duration resolves only within the library under analysis when it is a getter.** A *constant* is evaluated, which works across package boundaries; a getter is code, so its body is read from the AST and a getter declared in a dependency stays silent rather than being guessed at. The same applies to a parameter or a value returned by a function.

**UTC detection is syntactic.** `DateTime.utc(...)`, `.toUtc()`, a chain of shifts on either, and a local variable initialised from one are skipped. Anything less direct — a field, a parameter, a function's return value — is reported even when it holds a UTC `DateTime` at runtime. Silence those with `// ignore: many_lints/avoid_dst_unsafe_date_arithmetic`.

**The quick fix is narrower than the rule.** It applies only when the receiver is a simple identifier and the shift is a plain integer literal, because the replacement reads the receiver eight times — duplicating a call like `loadDate()` would change behaviour, not just semantics. The rule still reports; you write the replacement.

## Configuration

This rule is in the **`recommended`** preset, so it is on with `preset: recommended`
or `preset: opinionated`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_dst_unsafe_date_arithmetic: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_accessing_other_classes_private_members`](/many_lints/docs/rules/code-quality/avoid-accessing-other-classes-private-members/) — Make the underscore mean what everyone reads it as.
- [`avoid_commented_out_code`](/many_lints/docs/rules/code-quality/avoid-commented-out-code/) — Detect and flag commented-out code.
- [`avoid_complex_conditions`](/many_lints/docs/rules/code-quality/avoid-complex-conditions/) — Keep boolean conditions within an operand budget.
- [`avoid_deep_nesting`](/many_lints/docs/rules/code-quality/avoid-deep-nesting/) — Keep control flow within a nesting budget.
