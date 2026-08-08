---
title: avoid_nested_futures
description: "Don't declare Future<Future<T>>"
sidebar:
  label: avoid_nested_futures
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Async Safety</span>

This rule flags a type annotation that nests one future inside another — `Future<Future<T>>` or `FutureOr<Future<T>>`.

## Why use this rule

Dart flattens futures. An `async` function declared to return `Future<T>` produces `Future<T>` even when its body returns a future, and a single `await` unwraps all the way down. There is no value in the language that is genuinely a future of a future.

So the annotation is always wrong about what the code produces. It misleads readers into writing a second `await` that does nothing, and it makes the signature harder to read for no gain.

**See also:** [Dart: asynchronous programming](https://dart.dev/language/async)

## Don't

```dart
Future<Future<String>> loadName() async {
  return fetchName();
}
```

## Do

```dart
Future<String> loadName() async {
  return fetchName();
}
```

## Known limitations

Only explicit type annotations are checked — return types, parameter types, field and variable types. An inferred type is never reported, since Dart's own flattening means it can never actually be a nested future.

`Future<List<Future<T>>>` is not flagged: a list of futures is a legitimate shape, and only the directly nested case is an error.

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_nested_futures: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
