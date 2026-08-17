---
title: avoid_unnecessary_return
description: "Remove a bare `return;` that ends a void function"
sidebar:
  label: avoid_unnecessary_return
---

<span class="rule-badge rule-badge--version">v0.10.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

This rule flags a bare `return;` written as the last statement of a function that returns nothing, where control leaves the function whether it is there or not.

## Why use this rule

The statement changes nothing, but it does not read as though it changes nothing. `return` announces an early exit, so a reader stops to look for what is being skipped, and finds the closing brace.

It is usually a leftover from a change that moved or deleted the statements it once guarded. An early `return;` that genuinely skips later code is doing real work and is left alone.

## Don't

```dart
void process(Order order) {
  send(order);
  return; // nothing follows
}
```

## Do

```dart
void process(Order order) {
  send(order);
}
```

An early return stays:

```dart
void process(Order order) {
  if (order.isCancelled) return; // skips the call below
  send(order);
}
```

## Turning this rule off

This rule is in the **`opinionated`** preset.

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_unnecessary_return: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_early_return`](/many_lints/docs/rules/control-flow/prefer-early-return/) — Replace a body-wrapping if with an early-return guard.
- [`prefer_return_await`](/many_lints/docs/rules/control-flow/prefer-return-await/) — Detect missing await on returned Futures inside try-catch.
- [`avoid_cascade_after_if_null`](/many_lints/docs/rules/control-flow/avoid-cascade-after-if-null/) — Detect cascades after if-null operators without parentheses.
- [`avoid_collapsible_if`](/many_lints/docs/rules/control-flow/avoid-collapsible-if/) — Merge nested if statements with &amp;&amp;.
