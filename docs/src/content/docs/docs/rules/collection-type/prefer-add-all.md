---
title: prefer_add_all
description: "Replace an add-only loop with addAll"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_add_all
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Collection Type</span>

This rule flags a `for-in` loop whose only statement adds the loop variable to another collection.

## Why use this rule

`for (final x in source) target.add(x);` is `target.addAll(source)` spelled out across three lines. The loop form makes the reader decode control flow to recognise a single operation, and it hides the intent from anyone skimming.

`addAll` is also free to be more efficient — a `List` can grow its backing store once instead of on each `add`.

## Don't

```dart
for (final item in newItems) {
  selected.add(item);
}
```

## Do

```dart
selected.addAll(newItems);
```

## Known limitations

Only the exact copy pattern is reported. The rule stays silent whenever the loop does anything else:

- The added value is not the loop variable unchanged — `target.add(x.name)` is a map, not a copy.
- The body has more than one statement, or wraps the `add` in a condition.
- The loop is indexed (`for (var i = 0; ...)`) rather than `for-in`, since it may skip or reorder elements.
- The method is anything other than `add`.

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_add_all: false
```
