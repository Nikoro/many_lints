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

```dart
Object loadCount() async => 1;

FutureOr<int> loadOtherCount() async => 2;

Future<int>? loadNullableCount() async => 3;
```

## Do

```dart
Future<Object> loadCount() async => 1;

Future<int> loadOtherCount() async => 2;

Future<int> loadNullableCount() async => 3;
```

## Turning this rule off

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_correct_future_return_type: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
