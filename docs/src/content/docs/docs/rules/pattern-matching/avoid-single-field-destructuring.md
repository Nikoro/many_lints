---
title: avoid_single_field_destructuring
description: "Avoid single-field destructuring. Use direct property access instead."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_single_field_destructuring
---

| Property | Value |
|----------|-------|
| **Rule name** | `avoid_single_field_destructuring` |
| **Category** | Pattern Matching |
| **Severity** | Warning |
| **Has quick fix** | Yes |

## Problem

Avoid single-field destructuring. Use direct property access instead.

## Suggestion

Replace destructuring with direct property access on the expression.

## Example

```dart
// ignore_for_file: unused_local_variable

// avoid_single_field_destructuring
//
// Warns when a pattern variable declaration destructures only a single field.
// Single-field destructuring adds unnecessary complexity compared to direct
// property access.

class Config {
  final String name;
  final int timeout;

  const Config({required this.name, required this.timeout});
}

// ❌ Bad: Single-field destructuring (use direct property access instead)
void badExamples(Config config) {
  // LINT: Single field destructured from object pattern
  final Config(:name) = config;

  // LINT: Single named field destructured with renamed variable
  final Config(timeout: t) = config;
}

void badRecordExample(({int length}) record) {
  // LINT: Single field destructured from record pattern
  final (:length) = record;
}

// ✅ Good: Direct property access
void goodExamples(Config config) {
  final name = config.name;
  final t = config.timeout;
}

// ✅ Good: Multiple fields destructured (this is the right use case)
void goodMultipleFields(Config config) {
  final Config(:name, :timeout) = config;
}

// ✅ Good: Regular variable declaration (no destructuring)
void goodRegularDeclaration() {
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
