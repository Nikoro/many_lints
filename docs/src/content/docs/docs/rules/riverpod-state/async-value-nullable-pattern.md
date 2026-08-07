---
title: async_value_nullable_pattern
description: "Matching AsyncValue(:final value?) on a nullable value hides a legitimate null result."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: async_value_nullable_pattern
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Riverpod State</span>

Flags `AsyncValue(:final value?)` when the value type is nullable. The `?` pattern matches only when the value is non-null, which is not the same question as whether a value has loaded.

## Why use this rule

For an `AsyncValue<int?>`, a successfully loaded `null` is a real result. The `?` pattern rejects it, so that case silently falls through to the loading or error branch — the UI shows a spinner forever for data that actually arrived. `hasValue: true` asks the question you meant: *has this loaded?*

**See also:** [Riverpod - AsyncValue](https://riverpod.dev/docs/essentials/first_request)

## Don't

```dart
switch (asyncValue) { // AsyncValue<int?>
  case AsyncValue(:final value?): // LINT — a loaded null never matches
    print(value);
  default:
    return const CircularProgressIndicator();
}
```

## Do

```dart
switch (asyncValue) { // AsyncValue<int?>
  case AsyncValue(:final value, hasValue: true):
    print(value);
  default:
    return const CircularProgressIndicator();
}
```

The rule stays silent where the `?` pattern is precise:

```dart
// Non-nullable value: null can only mean "not loaded"
void fn(AsyncValue<int> asyncValue) {
  switch (asyncValue) {
    case AsyncValue(:final value?):
      print(value);
    default:
      break;
  }
}

// AsyncData.hasValue is always true, so the null check carries the meaning
void onData(AsyncValue<int?> asyncValue) {
  switch (asyncValue) {
    case AsyncData(:final value?):
      print(value);
    default:
      break;
  }
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      async_value_nullable_pattern: false
```
