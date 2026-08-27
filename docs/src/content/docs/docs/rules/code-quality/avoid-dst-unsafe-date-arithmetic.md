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

## Why use this rule

`Duration` measures *absolute elapsed time*. A calendar day is not always 24 hours long: in any zone that observes daylight saving time, one day each year is 23 hours and another is 25. Adding `Duration(days: 1)` moves by exactly 24 hours regardless, so it lands on the wrong wall-clock time whenever the span crosses a transition.

The result, in `Europe/Warsaw`:

```dart
DateTime(2025, 3, 29, 12).add(const Duration(days: 1));
// 2025-03-30 13:00 — an hour later than intended

DateTime(2025, 10, 25, 12).add(const Duration(days: 1));
// 2025-10-26 11:00 — an hour earlier than intended

DateTime(2025, 3, 30).add(const Duration(days: 1));
// 2025-03-31 01:00 — midnight is no longer midnight
```

That last one is the most damaging, because "start of day" is exactly what date arithmetic is usually computing. A daily boundary that drifts to 01:00 puts events in the wrong bucket, makes a "7 days ago" filter cover 6 days and 23 hours, and shifts a scheduled reminder by an hour twice a year.

The bug is invisible in testing: it reproduces on two days of the year, and never in UTC — so a CI machine running in UTC is guaranteed to stay green.

The `DateTime` constructor normalises out-of-range components against the calendar, so bumping the `day` component preserves the wall-clock time across a transition. It also handles month and year rollover: `day - 1` on the first of a month correctly lands on the last day of the previous one.

**See also:** [`DateTime.add` API docs](https://api.dart.dev/stable/dart-core/DateTime/add.html), which carries this exact caveat, and the [`DateTime` class overview](https://api.dart.dev/stable/dart-core/DateTime-class.html) on local vs. UTC time.

## Don't

```dart
// Shifts by 24 absolute hours, not by a calendar day
final tomorrow = today.add(const Duration(days: 1));

// Same bug written differently
final inTwoDays = today.add(const Duration(hours: 48));

// A week filter that is an hour short twice a year
final weekAgo = now.subtract(const Duration(days: 7));

// A name is not a defence: this is the shape the defect survives in
enum LeadTime {
  oneMonthBefore;

  Duration get offsetFromEvent => const Duration(days: 30);
}

final fireAt = occurrence.subtract(leadTime.offsetFromEvent);
```

## Do

```dart
// Calendar arithmetic: the constructor normalises against real days
final tomorrow = DateTime(
  today.year,
  today.month,
  today.day + 1,
  today.hour,
  today.minute,
);

// Or work in UTC, which has no transitions
final weekAgo = now.toUtc().subtract(const Duration(days: 7));
```

For anything more involved than shifting a day, use [`package:timezone`](https://pub.dev/packages/timezone), which models real zone rules.

## Known limitations

A `Duration` reached through a name is resolved back to where it was declared, so a getter, a constant or a local variable is read the same way a literal at the call site is. This matters because a named duration is exactly how the defect survives review — a lint that only saw literals would pass a codebase clean while its notification lead times drifted an hour twice a year.

Resolution has two halves, with different reach. A **constant** is evaluated, which works across library boundaries. A **getter** is code, not a constant, so nothing evaluates and its body is read from the AST — which reaches only the library under analysis. A getter declared in a dependency is therefore not resolved, and stays silent rather than being guessed at. The same applies to any duration the rule cannot pin down: a parameter, or a value returned by a function.

The rule only reports durations of day granularity — a `days:` argument, or an `hours:` argument that is a whole multiple of 24. Sub-day units are never flagged: `Duration(hours: 2)` genuinely means two elapsed hours, and absolute arithmetic is the correct semantics for it. A mixed `Duration(days: 1, hours: 2)` is not reported either, since it carries a sub-day component that day-component arithmetic cannot reproduce.

Receivers that are statically evident as UTC are skipped: `DateTime.utc(...)`, `.toUtc()`, a chain of shifts on either, and a local variable initialised from one. Anything less direct — a field, a parameter, a value returned by a function — is reported even when it happens to hold a UTC `DateTime` at runtime, because proving that would need flow analysis this rule does not attempt. If a receiver is known to be UTC but the rule cannot see it, silence the line with `// ignore: many_lints/avoid_dst_unsafe_date_arithmetic`.

The quick fix is deliberately narrower than the rule. It applies only when the receiver is a simple identifier and the shift is a plain integer literal, because the replacement reads the receiver eight times — duplicating a call like `loadDate()` would change behaviour, not just semantics.

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
