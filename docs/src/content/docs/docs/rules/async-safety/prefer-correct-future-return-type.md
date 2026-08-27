---
title: prefer_correct_future_return_type
description: "Expose async results as non-nullable Future values"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_correct_future_return_type
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Async Safety</span>

This rule flags an `async` function or method whose explicit return type hides the future it always produces. Broad types such as `dynamic` and `Object`, `FutureOr<T>`, and nullable futures make it possible for callers to overlook the asynchronous contract. Invalid generic return types are left to the Dart analyzer's `illegal_async_return_type` diagnostic.

The rule is part of the **`opinionated`** preset.

## Why use this rule

An `async` declaration always completes through a `Future`, even when its body immediately returns a value. Declaring that fact as `Future<T>` makes awaiting and error handling visible at every call site. `void` async callbacks remain allowed, as do declarations whose return type is inferred.

**See also:** [Dart asynchronous programming](https://dart.dev/language/async)

## Don't

`FutureOr<T>` on an `async` body is the common one. It reads as "maybe synchronous", but an `async` function never is — so every caller has to handle a branch that cannot happen:

```dart
import 'dart:async';

class Inbox {
  final List<String> _messages = [];

  FutureOr<int> unreadCount() async => _messages.length;
}
```

## Do

```dart
class Inbox {
  final List<String> _messages = [];

  Future<int> unreadCount() async => _messages.length;
}
```

### A nullable Future

`Future<int>?` says the call might not return a future at all. An `async` body always does; only the `int` inside can be null.

```dart
// Don't
Future<int>? unreadCount() async => 0;

// Do — the future is always there
Future<int> unreadCount() async => 0;

// Do — when the *result* is genuinely optional
Future<int?> lastReadIndex() async => null;
```

### A broad type hiding the future

`dynamic` and `Object` accept the future silently, so nothing at the call site suggests it needs awaiting:

```dart
// Don't
dynamic loadSettings() async => <String, Object?>{};

// Do
Future<Map<String, Object?>> loadSettings() async => <String, Object?>{};
```

### What is left alone

An `async` callback returning `void` is a legitimate shape and is not reported, nor is a declaration with no written return type:

```dart
void onSaved() async {                   // not reported
  await Future<void>.delayed(Duration.zero);
}

loadAll() async => <String, Object?>{};  // not reported: return type is inferred
```

## Turning this rule off

To disable this rule:

```yaml
# many_lints.yaml
rules:
  prefer_correct_future_return_type: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_future_ignore`](/many_lints/docs/rules/async-safety/avoid-future-ignore/) — Do not silently suppress Future errors with an unexplained ignore call.
- [`avoid_nested_futures`](/many_lints/docs/rules/async-safety/avoid-nested-futures/) — Don't declare Future&lt;Future&lt;T&gt;&gt;.
- [`avoid_passing_async_when_sync_expected`](/many_lints/docs/rules/async-safety/avoid-passing-async-when-sync-expected/) — Don't pass an async closure where a void-returning function is expected.
- [`avoid_redundant_async`](/many_lints/docs/rules/async-safety/avoid-redundant-async/) — Flag an async function that never awaits.
