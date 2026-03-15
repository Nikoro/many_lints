---
title: prefer_simpler_patterns_null_check
description: "Suggest simpler null-check patterns in if-case expressions"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_simpler_patterns_null_check
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

Warns when an if-case pattern uses `!= null && final field` instead of the simpler `final field?` syntax, or when a typed binding already guarantees non-nullability making the `!= null` check redundant. Dart 3 patterns offer concise null-checking syntax that should be preferred.

## Why use this rule

The `!= null && final field` pattern is verbose and can be replaced with `final field?` which does the same thing in fewer characters. When a type annotation is already present (e.g., `final String field`), the `!= null` check is doubly redundant since the non-nullable type already excludes null. Using the simpler pattern makes the code more idiomatic and easier to read.

**See also:** [Patterns](https://dart.dev/language/patterns)

## Don't

```dart
void bad(WithField object) {
  // Use `final field?` instead
  if (object.field case != null && final field) {
    print(field);
  }

  // Type annotation already guarantees non-null
  if (object.field case != null && final String field) {
    print(field);
  }
}
```

## Do

```dart
void good(WithField object) {
  // Nullable binding with postfix ?
  if (object.field case final field?) {
    print(field);
  }

  // Typed binding (type already excludes null)
  if (object.field case final String field) {
    print(field);
  }

  // Plain null check only
  if (object.field case != null) {
    print('not null');
  }
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_simpler_patterns_null_check: false
```
