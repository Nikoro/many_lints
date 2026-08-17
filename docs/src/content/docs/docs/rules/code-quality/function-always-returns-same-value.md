---
title: function_always_returns_same_value
description: "Flag a function whose every return yields the same constant"
sidebar:
  label: function_always_returns_same_value
---

<span class="rule-badge rule-badge--version">v0.10.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Code Quality</span>

This rule flags a function where every `return` yields the same constant, so the branching around them decides nothing.

## Why use this rule

Whatever the caller passes, the answer is fixed. Either a branch was meant to return something else and does not — the usual case, and a silent one — or the function should be a constant and its parameters dropped.

Only literal constants are compared, and only when there are at least two returns; one return of a constant is an ordinary function. A `return;` with no value, or a return inside a nested closure, means the rule cannot prove one fixed answer and stays quiet.

## Protocol callbacks are never reported

Some callbacks are *supposed* to return the same value on every path, because the value is a signal to a framework rather than an answer. `onNotification` must return `false` throughout to let a notification keep bubbling; the method exists for its side effect.

Two checks cover them: a set of known names (`onNotification`, `shouldRepaint`, …) plus any `on...` method, and — because a protocol callback can be given a descriptive name — the shape, where any parameter typed `...Notification` marks the method as a listener.

## Don't

```dart
int scoreFor(Player player) {
  if (player.isWinner) return 3;
  return 3; // the branch changes nothing
}
```

## Do

```dart
int scoreFor(Player player) {
  if (player.isWinner) return 3;
  return 0;
}
```

## Turning this rule off

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`.

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      function_always_returns_same_value: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`function_always_returns_null`](/many_lints/docs/rules/code-quality/function-always-returns-null/) — A nullable-returning function whose every path returns null.
- [`avoid_accessing_other_classes_private_members`](/many_lints/docs/rules/code-quality/avoid-accessing-other-classes-private-members/) — Make the underscore mean what everyone reads it as.
- [`avoid_commented_out_code`](/many_lints/docs/rules/code-quality/avoid-commented-out-code/) — Detect and flag commented-out code.
- [`avoid_complex_conditions`](/many_lints/docs/rules/code-quality/avoid-complex-conditions/) — Keep boolean conditions within an operand budget.
