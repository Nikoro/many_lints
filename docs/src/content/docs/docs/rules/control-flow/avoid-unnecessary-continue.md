---
title: avoid_unnecessary_continue
description: "Remove a `continue` that ends a loop body"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_unnecessary_continue
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

This rule flags a `continue` written as the last statement of a loop body, where control reaches the next iteration whether it is there or not.

## Why use this rule

The keyword changes nothing, but it does not read as though it changes nothing. `continue` announces that something below it is being skipped, so a reader stops to look for what — and finds the closing brace.

It is usually a leftover. Statements that once followed the `continue` were moved or deleted during a change, and the guard that protected them stayed behind. Removing it makes the loop say what it does.

A `continue` anywhere else is doing real work and is left alone, including one that ends a `then` branch to skip an `else`, and a labelled `continue` that targets an outer loop.

## Don't

```dart
for (final order in orders) {
  process(order);
  continue; // nothing follows; the loop continues anyway
}
```

## Do

```dart
for (final order in orders) {
  process(order);
}
```

A `continue` that actually skips something stays:

```dart
for (final order in orders) {
  if (order.isCancelled) continue; // skips the call below
  process(order);
}
```

## Turning this rule off

This rule is in the **`opinionated`** preset.

To disable this rule:

```yaml
# many_lints.yaml
rules:
  avoid_unnecessary_continue: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_cascade_after_if_null`](/many_lints/docs/rules/control-flow/avoid-cascade-after-if-null/) — Detect cascades after if-null operators without parentheses.
- [`avoid_collapsible_if`](/many_lints/docs/rules/control-flow/avoid-collapsible-if/) — Merge nested if statements with &amp;&amp;.
- [`avoid_constant_conditions`](/many_lints/docs/rules/control-flow/avoid-constant-conditions/) — Detect comparisons where both sides are constants.
- [`avoid_constant_switches`](/many_lints/docs/rules/control-flow/avoid-constant-switches/) — Detect switch statements on constant expressions.
