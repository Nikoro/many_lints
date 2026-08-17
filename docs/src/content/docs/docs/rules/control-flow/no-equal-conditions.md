---
title: no_equal_conditions
description: "Flag an if/else-if chain that repeats a condition"
sidebar:
  label: no_equal_conditions
---

<span class="rule-badge rule-badge--version">v0.10.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

This rule flags an `if`/`else if` chain that tests the same condition twice.

## Why use this rule

The second test can never be reached: the first branch already took every case it would have matched. Whatever the repeated branch does is dead code, and the case it was meant to handle silently falls through to `else` — so the bug shows up as a missing behaviour rather than an error.

It is a copy-paste result: a branch duplicated and its body edited while its condition was left alone.

Two independent `if` statements testing the same thing are not reported — the first may have changed the state the second reads. Only one chain is compared. A pattern case (`if (x case ...)`) is skipped, since two clauses that read alike need not test the same thing.

## Don't

```dart
if (status.isPending) {
  showSpinner();
} else if (status.isPending) { // never reached
  showRetry();
}
```

## Do

```dart
if (status.isPending) {
  showSpinner();
} else if (status.isFailed) {
  showRetry();
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
      no_equal_conditions: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`no_equal_switch_case`](/many_lints/docs/rules/control-flow/no-equal-switch-case/) — Flag two switch branches with identical bodies.
- [`no_equal_then_else`](/many_lints/docs/rules/control-flow/no-equal-then-else/) — Both branches of a condition are identical.
- [`avoid_constant_conditions`](/many_lints/docs/rules/control-flow/avoid-constant-conditions/) — Detect comparisons where both sides are constants.
- [`avoid_negated_conditions`](/many_lints/docs/rules/control-flow/avoid-negated-conditions/) — State the positive case first in an if/else.
