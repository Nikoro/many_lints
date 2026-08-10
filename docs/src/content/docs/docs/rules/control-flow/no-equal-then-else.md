---
title: no_equal_then_else
description: "Both branches of a condition are identical"
sidebar:
  label: no_equal_then_else
---

<span class="rule-badge rule-badge--version">v0.10.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

This rule flags an `if`/`else` or conditional expression whose branches are identical. If both branches do the same thing, the condition decides nothing.

## Why use this rule

Two identical branches mean one of two things: a branch was meant to differ and does not — the usual case, and a real bug — or the branching is dead weight that should collapse to a single statement.

The shape appears through copy-paste: the second branch is duplicated from the first with the intent to edit it, and the edit never happens. Nothing about it is a type error, so it survives review easily.

**See also:** [Dart: branches](https://dart.dev/language/branches)

## Don't

```dart
if (isAdmin) {
  showDashboard();
} else {
  showDashboard();   // the condition changes nothing
}
```

```dart
final label = isActive ? 'on' : 'on';
```

## Do

Make the branches differ, or drop the condition:

```dart
showDashboard();
```

## Known limitations

Branches are compared by source text, with a single-statement block reduced to that statement so `{ f(); }` and `f();` compare equal. Two branches that compute the same result by different code are not reported — that is beyond what a lint can judge.

An `else if` chain is skipped: comparing the first branch against a whole nested `if` says nothing useful. Two empty branches are skipped too, since that is usually code mid-way through being written.

## Configuration

This rule is in the **`core`** preset, so it is on with `preset: core`,
`preset: recommended` or `preset: all`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  no_equal_then_else: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
