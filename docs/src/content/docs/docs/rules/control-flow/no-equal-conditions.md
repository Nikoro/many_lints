---
title: no_equal_conditions
description: "Flag an if/else-if chain that repeats a condition"
sidebar:
  label: no_equal_conditions
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

This rule flags an `if`/`else if` chain that tests the same condition twice.

The second test can never be reached: the first branch already took every case it would have matched. Whatever the repeated branch does is dead code, and the case it was meant to handle silently falls through to `else` — so the bug shows up as a missing behaviour rather than an error.

## Don't

A branch duplicated and its body edited while its condition was left alone:

```dart
class Status {
  bool get isPending => true;
  bool get isFailed => false;
  bool get isDone => false;
}

void showSpinner() {}
void showRetry() {}
void showResult() {}

void render(Status status) {
  if (status.isPending) {
    showSpinner();
  } else if (status.isPending) {
    showRetry();
  } else if (status.isDone) {
    showResult();
  }
}
```

`showRetry()` never runs, and a failed status falls off the end of the chain in silence.

## Do

```dart
class Status {
  bool get isPending => true;
  bool get isFailed => false;
  bool get isDone => false;
}

void showSpinner() {}
void showRetry() {}
void showResult() {}

void render(Status status) {
  if (status.isPending) {
    showSpinner();
  } else if (status.isFailed) {
    showRetry();
  } else if (status.isDone) {
    showResult();
  }
}
```

## Known limitations

Conditions are compared by source text, so two spellings of the same test
(`a && b` and `b && a`) are not reported.

Only one chain is compared at a time. **Two independent `if` statements** are
never reported against each other, because the first may have changed the state
the second reads:

```dart
class Cart {
  bool get isEmpty => true;

  void addDefaultItem() {}
  void showCheckout() {}
}

void prepare(Cart cart) {
  if (cart.isEmpty) {
    cart.addDefaultItem();
  }

  // Not reported — the block above may have changed the answer.
  if (cart.isEmpty) {
    cart.showCheckout();
  }
}
```

A **pattern `if`** (`if (x case ...)`) is skipped entirely: two clauses that
read alike need not test the same thing.

## Turning this rule off

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`.

To disable this rule:

```yaml
# many_lints.yaml
rules:
  no_equal_conditions: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`no_equal_switch_case`](/many_lints/docs/rules/control-flow/no-equal-switch-case/) — Flag two switch branches with identical bodies.
- [`no_equal_then_else`](/many_lints/docs/rules/control-flow/no-equal-then-else/) — Both branches of a condition are identical.
- [`avoid_constant_conditions`](/many_lints/docs/rules/control-flow/avoid-constant-conditions/) — Detect comparisons where both sides are constants.
- [`avoid_negated_conditions`](/many_lints/docs/rules/control-flow/avoid-negated-conditions/) — State the positive case first in an if/else.
