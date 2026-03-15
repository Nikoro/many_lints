---
title: use_existing_destructuring
description: "Add properties to an existing destructuring instead of accessing them directly."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: use_existing_destructuring
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Pattern Matching</span>

When an object already has a destructuring declaration in the same scope, accessing additional properties directly on that object is inconsistent. The property should be added to the existing destructuring pattern instead, keeping all extractions in one place.

## Why use this rule

Mixing destructuring and direct property access on the same variable is confusing. If you already have `final Config(:name) = config;`, then accessing `config.timeout` separately misses the opportunity to keep all property extractions together. Adding `:timeout` to the existing pattern is cleaner and avoids repetition of the variable name.

**See also:** [Dart patterns](https://dart.dev/language/patterns)

## Don't

```dart
class Config {
  final String name;
  final int timeout;
  final bool verbose;

  const Config({
    required this.name,
    required this.timeout,
    required this.verbose,
  });
}

// Accessing property directly when destructuring already exists
void badDirectAccess(Config config) {
  final Config(:name) = config;
  print(config.timeout);
}

// Multiple undeclared property accesses
void badMultipleAccesses(Config config) {
  final Config(:name) = config;
  print(config.timeout);
  print(config.verbose);
}
```

## Do

```dart
// All needed properties are destructured
void goodFullDestructuring(Config config) {
  final Config(:name, :timeout) = config;
  print(name);
  print(timeout);
}

// No destructuring exists (no lint)
void goodNoDestructuring(Config config) {
  print(config.name);
  print(config.timeout);
}

// Access appears before the destructuring declaration (no lint)
void goodBeforeDestructuring(Config config) {
  print(config.timeout);
  final Config(:name) = config;
  print(name);
}

// Different variable than the one being destructured
void goodDifferentVariable(Config a, Config b) {
  final Config(:name) = a;
  print(b.timeout);
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      use_existing_destructuring: false
```
