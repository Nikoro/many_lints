---
title: avoid_collapsible_if
description: "Merge nested if statements with &&"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_collapsible_if
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

This rule flags an `if` statement whose body is nothing but another `if`, where neither has an `else`.

## Why use this rule

Two nested conditions with no `else` on either level are a conjunction written across two blocks. Merging them with `&&` states the real condition in one place and removes a level of indentation from everything inside.

The nested form also hides the relationship: a reader has to scan to the end of the outer block to confirm nothing else happens there.

## Don't

```dart
if (user != null) {
  if (user.isActive) {
    sendNotification(user);
  }
}
```

## Do

```dart
if (user != null && user.isActive) {
  sendNotification(user);
}
```

## Known limitations

The rule stays silent whenever the nesting could carry meaning:

- An `else` on either level.
- Any other statement in the outer block, before or after the inner `if`.
- A pattern `if (x case P)` on either level, which cannot be joined with `&&`.

The quick fix parenthesises an operand when needed, so merging a condition containing `||` does not change precedence.

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: all`. Add it to `preset: core` with
`avoid_collapsible_if: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_collapsible_if: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
