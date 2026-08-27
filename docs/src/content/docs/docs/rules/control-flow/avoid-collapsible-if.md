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

Flags an `if` whose body is nothing but another `if`, where neither has an `else`. Two nested conditions with no `else` are a conjunction written across two blocks.

## Don't

```dart
class User {
  bool isActive = true;
}

void notify(User? user) {
  if (user != null) {
    if (user.isActive) {
      sendNotification(user);
    }
  }
}

void sendNotification(User user) {}
```

## Do

```dart
class User {
  bool isActive = true;
}

void notify(User? user) {
  if (user != null && user.isActive) {
    sendNotification(user);
  }
}

void sendNotification(User user) {}
```

### Braces are optional on either level

The rule matches the inner `if` whether it is the sole statement of a block or written bare:

```dart
void log(String? message, bool verbose) {
  if (verbose)
    if (message != null) print(message);
}
```

That collapses the same way:

```dart
void log(String? message, bool verbose) {
  if (verbose && message != null) print(message);
}
```

### A condition with `||` keeps its parentheses

The quick fix parenthesises an operand when merging would otherwise change precedence, so the meaning is preserved:

```dart
void handle(bool retryable, int status, bool offline) {
  // Don't
  if (retryable) {
    if (status >= 500 || offline) {
      scheduleRetry();
    }
  }

  // Do — the fix writes this, not `retryable && status >= 500 || offline`
  if (retryable && (status >= 500 || offline)) {
    scheduleRetry();
  }
}

void scheduleRetry() {}
```

## Known limitations

The rule stays silent whenever the nesting could carry meaning:

- An `else` on either level.
- Any other statement in the outer block, before or after the inner `if`.
- A pattern `if (x case P)` on either level, which cannot be joined with `&&`.

Three collapsible levels produce two reports — one per mergeable pair — and merging them all gives a single `&&` chain.

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`avoid_collapsible_if: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_collapsible_if: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_redundant_else`](/many_lints/docs/rules/control-flow/avoid-redundant-else/) — Drop the else when the if branch always exits.
- [`prefer_early_return`](/many_lints/docs/rules/control-flow/prefer-early-return/) — Replace a body-wrapping if with an early-return guard.
- [`prefer_immediate_return`](/many_lints/docs/rules/code-quality/prefer-immediate-return/) — Return an expression directly instead of via a throwaway variable.
- [`avoid_cascade_after_if_null`](/many_lints/docs/rules/control-flow/avoid-cascade-after-if-null/) — Detect cascades after if-null operators without parentheses.
