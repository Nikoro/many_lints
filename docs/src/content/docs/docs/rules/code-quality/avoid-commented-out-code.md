---
title: avoid_commented_out_code
description: "This comment looks like commented-out code."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_commented_out_code
---

| Property | Value |
|----------|-------|
| **Rule name** | `avoid_commented_out_code` |
| **Category** | Code Quality |
| **Severity** | Warning |
| **Has quick fix** | Yes |

## Problem

This comment looks like commented-out code.

## Suggestion

Remove commented-out code. Use version control to track old code instead.

## Example

```dart
// ignore_for_file: unused_local_variable

// avoid_commented_out_code
//
// Warns when commented-out code is found. Use version control to
// track old code instead of keeping it in comments.

// Bad: Commented-out function definition
class BadExamples {
  // LINT: This looks like commented-out code
  // void apply(String value) {
  //   print(value);
  // }

  // LINT: Commented-out variable declaration
  // final x = 42;

  // LINT: Commented-out import statement
  // import 'dart:async';

  void another() {}
}

// Good: Regular descriptive comments
class GoodExamples {
  // This method handles the main processing logic
  // and delegates to the appropriate handler

  // Temporarily disabled, enable in 1.0
  void another() {}
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_commented_out_code: false
```
