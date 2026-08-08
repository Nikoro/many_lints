---
title: avoid_empty_spread
description: "Remove spreads of empty collection literals"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_empty_spread
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Collection Type</span>

This rule flags a spread element whose operand is an empty collection literal — `...[]`, `...{}`, `...<int>[]`.

## Why use this rule

Spreading an empty literal contributes nothing to the surrounding collection. It is dead syntax, usually left behind after a refactor removed the elements, or written as a placeholder that was never filled in.

Beyond the noise, it misleads: a reader scanning a widget's `children` sees a spread and assumes something conditional is happening there.

## Don't

```dart
Column(
  children: [
    const Header(),
    // Contributes nothing
    ...[],
    const Footer(),
  ],
)
```

## Do

```dart
Column(
  children: [
    const Header(),
    const Footer(),
  ],
)
```

If the spread was a placeholder for conditional content, make the condition explicit:

```dart
Column(
  children: [
    const Header(),
    if (showDetails) const Details(),
    const Footer(),
  ],
)
```

## Known limitations

Only literal empty collections are reported. A spread of a variable that happens to be empty at runtime (`...items`) is never flagged, since emptiness is not knowable at analysis time. Null-aware spreads of a variable (`...?items`) are likewise left alone.

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_empty_spread: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
