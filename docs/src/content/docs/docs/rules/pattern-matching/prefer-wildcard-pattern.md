---
title: prefer_wildcard_pattern
description: "Use the wildcard pattern '_' instead of 'Object()' for catch-all cases."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_wildcard_pattern
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Pattern Matching</span>

Using `Object()` as a catch-all pattern in switch expressions, switch statements, or if-case conditions is functionally equivalent to the wildcard pattern `_`. The wildcard is more idiomatic in Dart and instantly recognizable as "match anything."

## Why use this rule

`_` is the standard Dart idiom for "I don't care about the value." Using `Object()` instead adds visual noise and may confuse readers into thinking the pattern is doing something specific. The wildcard pattern is shorter, clearer, and universally understood.

**See also:** [Dart patterns](https://dart.dev/language/patterns)

## Don't

```dart
// Using Object() as a catch-all pattern
String classify(Object object) {
  return switch (object) {
    int() => 'int',
    Object() => 'other',
  };
}

void statement(Object object) {
  switch (object) {
    case int():
      break;
    case Object():
      break;
  }
}

void ifCase(Object object) {
  if (object case Object()) {}
}
```

## Do

```dart
// Using the wildcard pattern _
String classify(Object object) {
  return switch (object) {
    int() => 'int',
    _ => 'other',
  };
}

void statement(Object object) {
  switch (object) {
    case int():
      break;
    case _:
      break;
  }
}

// Object() with field destructuring is fine — it extracts values
String withFields(Object object) {
  return switch (object) {
    int() => 'int',
    Object(hashCode: final h) => 'hash: $h',
    _ => 'other',
  };
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_wildcard_pattern: false
```
