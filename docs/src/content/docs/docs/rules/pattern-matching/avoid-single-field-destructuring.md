---
title: avoid_single_field_destructuring
description: "Avoid destructuring a single field when direct property access is simpler."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_single_field_destructuring
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Pattern Matching</span>

Destructuring a single field from an object or record pattern adds unnecessary syntactic overhead. Direct property access like `config.name` is simpler and clearer when only one value is needed.

## Why use this rule

Destructuring shines when extracting multiple values at once. For a single field, `final Config(:name) = config;` is more verbose than `final name = config.name;` with no readability benefit. This rule encourages destructuring only when it genuinely simplifies the code.

**See also:** [Dart patterns](https://dart.dev/language/patterns)

## Don't

```dart
class Config {
  final String name;
  final int timeout;

  const Config({required this.name, required this.timeout});
}

void example(Config config) {
  // Single field destructured from object pattern
  final Config(:name) = config;

  // Single named field destructured with renamed variable
  final Config(timeout: t) = config;
}

void recordExample(({int length}) record) {
  // Single field destructured from record pattern
  final (:length) = record;
}
```

## Do

```dart
// Direct property access
void example(Config config) {
  final name = config.name;
  final t = config.timeout;
}

// Multiple fields destructured (this is the right use case)
void multipleFields(Config config) {
  final Config(:name, :timeout) = config;
}

// Regular variable declaration (no destructuring)
void regularDeclaration() {
  final x = 42;
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_single_field_destructuring: false
```
