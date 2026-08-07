---
title: avoid_duplicate_collection_elements
description: "Don't repeat the same element in a list literal"
sidebar:
  label: avoid_duplicate_collection_elements
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Collection Type</span>

This rule flags a list literal that contains the same element more than once.

## Why use this rule

A hand-written literal listing the same value twice is almost always a mistake — one entry was meant to be a different constant, enum value, or field. Nothing fails: the list simply carries a duplicate, and whatever consumes it does the work twice or shows the entry twice.

Sets and maps are deliberately out of scope. The analyzer already reports duplicate set elements and duplicate map keys natively, so covering them here would double-report.

## Don't

```dart
const supportedLocales = [
  Locale('en'),
  Locale('de'),
  Locale('en'),
];
```

## Do

```dart
const supportedLocales = [
  Locale('en'),
  Locale('de'),
  Locale('fr'),
];
```

## Known limitations

Elements are compared by source text, which is only sound for expressions that always evaluate the same way. The rule therefore compares only literals, identifiers, and property accesses — `[next(), next()]` is never reported, since two calls may legitimately produce different values.

Analysis also stops at the first non-value element. A literal containing a spread or an `if` element has an unknown contents, so nothing after it can be judged.

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_duplicate_collection_elements: false
```
