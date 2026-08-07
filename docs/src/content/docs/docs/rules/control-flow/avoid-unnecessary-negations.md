---
title: avoid_unnecessary_negations
description: "Collapse double negations"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_unnecessary_negations
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

This rule flags a negation applied to something already negated — `!!flag` and `!(a != b)`.

## Why use this rule

A double negation states a positive condition the long way. The reader has to unwind both operators before knowing what is actually being tested, and it is easy to miscount when the expression is longer.

These usually appear when a condition is inverted during a change and the inner expression is left as it was.

## Don't

```dart
if (!!isEnabled) {
  start();
}

if (!(status != Status.active)) {
  activate();
}
```

## Do

```dart
if (isEnabled) {
  start();
}

if (status == Status.active) {
  activate();
}
```

## Known limitations

Only two shapes are reported: `!` applied to a `!` expression, and `!` applied to a `!=` comparison. Parentheses around either are unwrapped first, so `!(!flag)` is caught.

A negated `==` (`!(a == b)`) is deliberately excluded — it is a single negation, and rewriting it to `!=` is a style preference rather than a redundancy. Negated relational comparisons are handled by [`avoid_inverted_boolean_checks`](/docs/rules/control-flow/avoid-inverted-boolean-checks/) instead, so the same code is never reported twice.

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_unnecessary_negations: false
```
