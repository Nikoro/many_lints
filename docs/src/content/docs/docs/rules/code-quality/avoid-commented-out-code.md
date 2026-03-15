---
title: avoid_commented_out_code
description: "Detect and flag commented-out code."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_commented_out_code
---

<span class="rule-badge rule-badge--version">v0.3.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Code Quality</span>

Flags comments that look like commented-out Dart code rather than descriptive text. This includes commented-out function definitions, variable declarations, import statements, and other recognizable code patterns. The quick fix removes the flagged comment block.

## Why use this rule

Commented-out code is technical debt that clutters the codebase and confuses readers about what is intentional. Version control already preserves old code, making commented-out blocks unnecessary. Removing them keeps the codebase clean and reduces cognitive load during code review.

**See also:** [Effective Dart: Documentation](https://dart.dev/effective-dart/documentation)

## Don't

```dart
class BadExamples {
  // void apply(String value) {
  //   print(value);
  // }

  // final x = 42;

  // import 'dart:async';

  void another() {}
}
```

## Do

```dart
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
