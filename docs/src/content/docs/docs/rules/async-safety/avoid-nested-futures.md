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

Dart flattens futures in the two places people rely on: an `async` function declared to return `Future<T>` produces `Future<T>` even when its body returns a future, and `Future.value` infers a flattened type.

Flattening does **not** rewrite an explicitly written nested annotation, and `await` unwraps exactly one level:

```dart
Future<Future<String>> declared() async => fetchName();

final a = await declared();          // a is a Future<String>, not a String
final b = await (await declared());  // 'nick' — two awaits needed
```

So the annotation produces a value that behaves unlike every neighbouring future: a caller who awaits it once, as they would anything else, silently holds a `Future<String>` where a `String` was expected. Declaring the inner type directly removes the trap and makes the signature honest.

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

This rule is in the **`core`** preset, so it is on with `preset: core`,
`preset: recommended` or `preset: all`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_nested_futures: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
