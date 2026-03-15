---
title: avoid_only_rethrow
description: "Detect catch clauses that only rethrow the exception"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_only_rethrow
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

Warns when a catch clause contains only a `rethrow` statement. Such catch clauses are completely redundant -- they catch an exception only to immediately rethrow it, adding no value. The entire try-catch block can be removed.

## Why use this rule

A catch clause that only rethrows does not handle, log, or transform the exception in any way. It adds indentation and visual noise without changing behavior. Removing the redundant try-catch makes the code simpler and communicates that no error handling is happening at this level.

**See also:** [Exceptions](https://dart.dev/language/error-handling)

## Don't

```dart
void bad() {
  // Redundant catch clause
  try {
    doSomething();
  } catch (e) {
    rethrow;
  }

  // Same with typed on clause
  try {
    doSomething();
  } on Exception {
    rethrow;
  }

  // With stack trace parameter, still redundant
  try {
    doSomething();
  } catch (e, s) {
    rethrow;
  }
}
```

## Do

```dart
void good() {
  // Logging before rethrowing is meaningful
  try {
    doSomething();
  } catch (e) {
    print('Error: $e');
    rethrow;
  }

  // Conditional rethrow with handling
  try {
    doSomething();
  } catch (e) {
    if (e is FormatException) {
      handleFormat(e);
      return;
    }
    rethrow;
  }

  // No try-catch needed at all if you're just rethrowing
  doSomething();
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_only_rethrow: false
```
