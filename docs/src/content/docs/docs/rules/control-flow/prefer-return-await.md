---
title: prefer_return_await
description: "Detect missing await on returned Futures inside try-catch"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_return_await
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

Warns when a `Future` is returned without `await` inside a try-catch block in an async function. Without `await`, any exception thrown by the Future will not be caught by the surrounding catch block, silently bypassing your error handling.

## Why use this rule

When you write `return asyncOp()` inside a try-catch, the Future is returned to the caller without being awaited. If `asyncOp()` throws, the exception propagates to the caller instead of being caught by the local catch block. Adding `await` ensures the Future completes within the try-catch scope, so exceptions are properly caught and handled.

**See also:** [Asynchronous programming](https://dart.dev/libraries/async/async-await)

## Don't

```dart
Future<String> badReturnInTry() async {
  try {
    // Exception from asyncOp() won't be caught
    return asyncOp();
  } catch (e) {
    return 'fallback';
  }
}

Future<String> badReturnInCatch() async {
  try {
    throw Exception();
  } catch (e) {
    // Exception from asyncOp() won't be caught
    return asyncOp();
  }
}
```

## Do

```dart
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

// Returning Future outside try-catch is fine
Future<String> goodReturnOutsideTryCatch() async {
  return asyncOp();
}

// Non-async function returning Future in try-catch is fine
Future<String> goodNonAsync() {
  try {
    return asyncOp();
  } catch (e) {
    return Future.value('fallback');
  }
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_return_await: false
```
