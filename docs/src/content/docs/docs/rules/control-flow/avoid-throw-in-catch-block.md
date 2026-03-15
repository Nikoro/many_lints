---
title: avoid_throw_in_catch_block
description: "Detect throw expressions inside catch blocks"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_throw_in_catch_block
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

Warns when a `throw` expression is used inside a catch block. Throwing a new exception (or re-throwing the caught one with `throw e`) discards the original stack trace, making debugging significantly harder. Use `rethrow` or `Error.throwWithStackTrace()` instead.

## Why use this rule

When you use `throw` inside a catch block, the original stack trace is lost. This means error reports and logs will point to the catch block instead of the actual source of the error. Using `rethrow` preserves the full stack trace, and `Error.throwWithStackTrace()` lets you throw a different exception while keeping the original stack trace attached.

**See also:** [Exceptions](https://dart.dev/language/error-handling)

## Don't

```dart
void bad() {
  // throw loses original stack trace
  try {
    networkDataProvider();
  } on Object {
    throw RepositoryException();
  }

  // throw with caught exception still loses stack trace
  try {
    networkDataProvider();
  } catch (e) {
    throw e;
  }

  // throw with logic before it
  try {
    networkDataProvider();
  } catch (e) {
    print(e);
    throw RepositoryException('failed');
  }
}
```

## Do

```dart
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
