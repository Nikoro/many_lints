---
title: avoid_duplicate_collection_elements
description: "Don't repeat the same element in a collection literal"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_duplicate_collection_elements
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Collection Type</span>

This rule flags a collection literal that contains the same element more than once. The quick fix removes the duplicate, keeping the first occurrence.

## Why use this rule

A hand-written literal listing the same value twice is almost always a mistake — one entry was meant to be a different constant, enum value, or field. Nothing fails: the list simply carries a duplicate, and whatever consumes it does the work twice or shows the entry twice.

Repeated spreads and repeated `if` elements are reported too. Writing `...items` twice either duplicates every value or is dead weight, and the same holds for two identical `if` elements.

Plain values in sets and maps are deliberately out of scope. The analyzer already reports duplicate set elements and duplicate map keys natively, so covering them here would double-report. Spreads inside a set or map *are* checked, since the analyzer does not catch those.

## Don't

```dart
const supportedLocales = [
  Locale('en'),
  Locale('de'),
  Locale('en'),
];

final combined = [...base, ...base];

final entries = [
  if (items.isNotEmpty) 'value',
  if (items.isNotEmpty) 'value',
];
```

## Do

```dart
const supportedLocales = [
  Locale('en'),
  Locale('de'),
  Locale('fr'),
];

final combined = [...base, ...extra];

final entries = [
  if (items.isNotEmpty) 'value',
  if (items.isEmpty) 'empty',
];
```

## Known limitations

Elements are compared by source text, which is only sound for expressions that always evaluate the same way. The rule therefore compares only literals, identifiers, and property accesses — `[next(), next()]` is never reported, since two calls may legitimately produce different values. The same applies to spreads: `[...fetch(), ...fetch()]` is left alone.

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_duplicate_collection_elements: false
```
