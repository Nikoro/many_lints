---
title: avoid_throw_in_catch_block
description: "Avoid using throw inside a catch block."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_throw_in_catch_block
---

| Property | Value |
|----------|-------|
| **Rule name** | `avoid_throw_in_catch_block` |
| **Category** | Control Flow |
| **Severity** | Warning |
| **Has quick fix** | Yes |

## Problem

Avoid using throw inside a catch block.

## Suggestion

Use Error.throwWithStackTrace() to preserve the stack trace.

## Example

```dart
// ignore_for_file: unused_local_variable, unused_catch_clause

// avoid_throw_in_catch_block
//
// Warns when a `throw` expression is used inside a catch block.
// Throwing inside catch loses the original stack trace — use
// Error.throwWithStackTrace() or rethrow instead.

class RepositoryException implements Exception {
  RepositoryException([this.message]);
  final String? message;
}

void networkDataProvider() {}

// ❌ Bad: Throwing a new exception in a catch block
void bad() {
  // LINT: throw loses original stack trace
  try {
    networkDataProvider();
  } on Object {
    throw RepositoryException();
  }

  // LINT: throw with caught exception still loses stack trace
  try {
    networkDataProvider();
  } catch (e) {
    throw e;
  }

  // LINT: throw with logic before it
  try {
    networkDataProvider();
  } catch (e) {
    print(e);
    throw RepositoryException('failed');
  }
}

// ✅ Good: Preserving the original stack trace
void good() {
  // Use Error.throwWithStackTrace to preserve the stack trace
  try {
    networkDataProvider();
  } catch (_, stack) {
    Error.throwWithStackTrace(RepositoryException(), stack);
  }

  // Use rethrow to re-throw the original exception
  try {
    networkDataProvider();
  } catch (e) {
    print(e);
    rethrow;
  }

  // Throw inside a closure is fine — it's not in the catch scope
  try {
    networkDataProvider();
  } catch (e) {
    final callback = () {
      throw RepositoryException();
    };
    callback();
  }
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_throw_in_catch_block: false
```
