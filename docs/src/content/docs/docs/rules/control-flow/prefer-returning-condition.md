---
title: prefer_returning_condition
description: "Return the condition instead of true/false branches"
sidebar:
  label: prefer_returning_condition
---

<span class="rule-badge rule-badge--version">v0.10.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

This rule flags an `if` that returns `true` with a following `return false` (or the reverse).

## Why use this rule

`if (x > 0) return true; return false;` is the condition itself, spelled out in three lines. `return x > 0;` says it once, and the reader does not have to check that the two branches really are opposites — which is exactly the check that gets skipped when one of them is later edited.

Both branches returning the *same* literal is a different mistake, reported by [`function_always_returns_same_value`](/many_lints/docs/rules/code-quality/function-always-returns-same-value/). A pattern case (`if (x case ...)`) is skipped, since it binds variables the returned expression may use.

## Don't

```dart
bool isEligible(Player player) {
  if (player.rating > 1200) {
    return true;
  }
  return false;
}
```

## Do

```dart
bool isEligible(Player player) => player.rating > 1200;
```

## Turning this rule off

This rule is in the **`opinionated`** preset.

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_returning_condition: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
