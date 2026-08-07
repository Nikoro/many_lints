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

This rule flags a negation that can be removed without changing the meaning — `!!flag`, `!(a != b)`, `!true`, and `!a == !b`.

## Why use this rule

A double negation states a positive condition the long way. The reader has to unwind both operators before knowing what is actually being tested, and it is easy to miscount when the expression is longer.

Negating a boolean literal (`!true`) is just the other literal written indirectly. Negating both sides of an equality (`!a == !b`) cancels out entirely — the comparison gives the same answer without either `!`.

These usually appear when a condition is inverted during a change and the inner expression is left as it was.

## Don't

```dart
if (!!isEnabled) {
  start();
}

if (!(status != Status.active)) {
  activate();
}

if (!true) {
  unreachable();
}

if (!isReady == !isLoaded) {
  sync();
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

if (false) {
  unreachable();
}

if (isReady == isLoaded) {
  sync();
}
```

## Known limitations

Four shapes are reported: `!` applied to a `!` expression, `!` applied to a `!=` comparison, `!` applied to a boolean literal, and `==`/`!=` with a negation on *both* sides. Parentheses are unwrapped first, so `!(!flag)` is caught.

A single negation in a comparison (`!a == b`) is left alone — removing it would change the result. A negated `==` (`!(a == b)`) is also deliberately excluded: it is a single negation, and rewriting it to `!=` is a style preference rather than a redundancy. Negated relational comparisons are handled by [`avoid_inverted_boolean_checks`](/docs/rules/control-flow/avoid-inverted-boolean-checks/) instead, so the same code is never reported twice.

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_unnecessary_negations: false
```
