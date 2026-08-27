---
title: prefer_returning_condition
description: "Return the condition instead of true/false branches"
sidebar:
  label: prefer_returning_condition
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

This rule flags an `if` that returns `true` with a following `return false` (or the reverse).

`if (x > 0) return true; return false;` is the condition itself, spelled out in three lines. `return x > 0;` says it once, and the reader does not have to check that the two branches really are opposites — which is exactly the check that gets skipped when one of them is later edited.

## Don't

An `if` with the opposite literal on the next statement:

```dart
class Player {
  int get rating => 0;
}

bool isEligible(Player player) {
  if (player.rating > 1200) {
    return true;
  }
  return false;
}
```

The explicit `else` is the same mistake:

```dart
class Player {
  int get rating => 0;
}

bool isEligible(Player player) {
  if (player.rating > 1200) {
    return true;
  } else {
    return false;
  }
}
```

An inverted pair works out to the negated condition:

```dart
class Player {
  bool get isBanned => false;
}

bool canPlay(Player player) {
  if (player.isBanned) {
    return false;
  }
  return true;
}
```

## Do

```dart
class Player {
  int get rating => 0;
  bool get isBanned => false;
}

bool isEligible(Player player) => player.rating > 1200;

bool canPlay(Player player) => !player.isBanned;
```

## Known limitations

Both branches returning the **same** literal is a different mistake, reported by
[`function_always_returns_same_value`](/many_lints/docs/rules/code-quality/function-always-returns-same-value/) instead.

A **pattern case** (`if (x case final int n)`) is skipped, since it binds
variables the returned expression may use.

Only a bare `true`/`false` literal counts. `return isEligible;` after an `if`
is a value, not a spelled-out condition, and is not reported.

## Turning this rule off

This rule is in the **`opinionated`** preset.

To disable this rule:

```yaml
# many_lints.yaml
rules:
  prefer_returning_condition: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_inverted_boolean_checks`](/many_lints/docs/rules/control-flow/avoid-inverted-boolean-checks/) — Use the opposite operator instead of negating a comparison.
- [`avoid_negated_conditions`](/many_lints/docs/rules/control-flow/avoid-negated-conditions/) — State the positive case first in an if/else.
- [`avoid_unnecessary_negations`](/many_lints/docs/rules/control-flow/avoid-unnecessary-negations/) — Collapse double negations.
- [`avoid_unmodified_loop_condition`](/many_lints/docs/rules/control-flow/avoid-unmodified-loop-condition/) — A while loop whose condition the body can never change.
