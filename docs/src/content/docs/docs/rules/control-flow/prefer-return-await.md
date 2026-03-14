---
title: prefer_return_await
description: "Missing await on returned Future inside try-catch block."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_return_await
---

| Property | Value |
|----------|-------|
| **Rule name** | `prefer_return_await` |
| **Category** | Control Flow |
| **Severity** | Warning |
| **Has quick fix** | Yes |

## Problem

Missing await on returned Future inside try-catch block.

## Suggestion

Add await before the returned expression.

## Example

```dart
// ignore_for_file: unused_local_variable, unused_catch_clause

// prefer_return_await
//
// Warns when a Future is returned without `await` inside a try-catch block.
// Not awaiting a Future leads to any potential exception not being caught
// by the catch block.

// ❌ Bad: Returning Future without await in try-catch

Future<String> badReturnInTry() async {
  try {
    // LINT: Exception from asyncOp() won't be caught
    return asyncOp();
  } catch (e) {
    return 'fallback';
  }
}

Future<String> badReturnInCatch() async {
  try {
    throw Exception();
  } catch (e) {
    // LINT: Exception from asyncOp() won't be caught
    return asyncOp();
  }
}

// ✅ Good: Returning with await in try-catch

Future<String> goodReturnAwaitInTry() async {
  try {
    return await asyncOp();
  } catch (e) {
    return 'fallback';
  }
}

Future<String> goodReturnAwaitInCatch() async {
  try {
    throw Exception();
  } catch (e) {
    return await asyncOp();
  }
}

// ✅ Good: Returning Future outside try-catch is fine
Future<String> goodReturnOutsideTryCatch() async {
  return asyncOp();
}

// ✅ Good: Non-async function returning Future in try-catch is fine
Future<String> goodNonAsync() {
  try {
    return asyncOp();
  } catch (e) {
    return Future.value('fallback');
  }
}

Future<String> asyncOp() async => 'result';
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_return_await: false
```
