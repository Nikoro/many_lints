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

This rule flags a negation that can be removed without changing the meaning. Four shapes are reported.

## Don't

**A negation over a negation.** Usually the result of inverting a condition and leaving the inner expression as it was:

```dart
void start() {}

void toggle(bool isEnabled) {
  if (!!isEnabled) {
    start();
  }
}
```

**A negation over `!=`.** The `!` and the `!=` cancel:

```dart
enum Status { active, archived }

void activate() {}

void refresh(Status status) {
  if (!(status != Status.active)) {
    activate();
  }
}
```

**A negation over a boolean literal.** `!true` is just `false` written the long way — most often a feature flag that was flipped in place:

```dart
void renderLegacyBanner() {}

void render() {
  if (!true) {
    renderLegacyBanner();
  }
}
```

**A negation on both sides of a comparison.** Negating both operands leaves the answer unchanged:

```dart
void sync() {}

void check(bool isReady, bool isLoaded) {
  if (!isReady == !isLoaded) {
    sync();
  }
}
```

## Do

The quick fix removes the redundant operators, one diagnostic at a time:

```dart
enum Status { active, archived }

void start() {}
void activate() {}
void renderLegacyBanner() {}
void sync() {}

void examples(bool isEnabled, Status status, bool isReady, bool isLoaded) {
  if (isEnabled) {
    start();
  }

  if (status == Status.active) {
    activate();
  }

  if (false) {
    renderLegacyBanner();
  }

  if (isReady == isLoaded) {
    sync();
  }
}
```

## Known limitations

Four shapes are reported: `!` applied to a `!` expression, `!` applied to a `!=` comparison, `!` applied to a boolean literal, and `==`/`!=` with a negation on *both* sides. Parentheses are unwrapped first, so `!(!flag)` is caught.

A single negation in a comparison (`!a == b`) is left alone — removing it would change the result. A negated `==` (`!(a == b)`) is also deliberately excluded: it is a single negation, and rewriting it to `!=` is a style preference rather than a redundancy. Negated relational comparisons are handled by [`avoid_inverted_boolean_checks`](/many_lints/docs/rules/control-flow/avoid-inverted-boolean-checks/) instead, so the same code is never reported twice.

## Configuration

This rule is in the **`core`** preset, so it is on with `preset: core`,
`preset: recommended` or `preset: opinionated`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_unnecessary_negations: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_inverted_boolean_checks`](/many_lints/docs/rules/control-flow/avoid-inverted-boolean-checks/) — Use the opposite operator instead of negating a comparison.
- [`avoid_negated_conditions`](/many_lints/docs/rules/control-flow/avoid-negated-conditions/) — State the positive case first in an if/else.
- [`prefer_returning_condition`](/many_lints/docs/rules/control-flow/prefer-returning-condition/) — Return the condition instead of true/false branches.
- [`avoid_cascade_after_if_null`](/many_lints/docs/rules/control-flow/avoid-cascade-after-if-null/) — Detect cascades after if-null operators without parentheses.
