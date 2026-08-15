---
title: avoid_self_compare
description: "Flag a value compared against itself with compareTo"
sidebar:
  label: avoid_self_compare
---

<span class="rule-badge rule-badge--version">v0.10.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Code Quality</span>

This rule flags `a.compareTo(a)`, where the receiver and the argument are the same expression, so the result is always `0`.

## Why use this rule

A comparison that always answers `0` decides nothing. A sort built on it leaves the list in its original order, and a conditional guarded by it always takes the same branch — quietly, with no error to trace back to.

It is nearly always a typo. The wrong name gets picked out of an autocomplete list, or a `compareTo` is left half-edited after a field is renamed. The code compiles and the types check, so nothing else catches it.

Only receivers and arguments that are safe to evaluate twice are compared. `next().compareTo(next())` reads the same but calls twice, and a hand-written getter can report a moving value, so both are left alone.

The operator form of this mistake (`a == a`, `a < a`) is reported by [`avoid_equal_expressions`](/many_lints/docs/rules/control-flow/avoid-equal-expressions/), so the two rules never report the same line.

**See also:** [`Comparable.compareTo`](https://api.dart.dev/stable/dart-core/Comparable/compareTo.html)

## Don't

```dart
// Always 0 — the list keeps its original order.
people.sort((a, b) => a.surname.compareTo(a.surname));

if (current.compareTo(current) > 0) {
  // unreachable
}
```

## Do

```dart
people.sort((a, b) => a.surname.compareTo(b.surname));

if (current.compareTo(previous) > 0) {
  advance();
}
```

## Turning this rule off

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_self_compare: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
