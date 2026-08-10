---
title: missing_provider_scope
description: "Flutter applications using Riverpod must have a ProviderScope at the root of the widget tree."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: missing_provider_scope
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Riverpod State</span>

Flags a call to `runApp()` whose root widget is not a `ProviderScope`. Riverpod keeps all provider state inside a `ProviderScope`, so an app without one at the root cannot read any provider.

## Why use this rule

Nothing about a missing `ProviderScope` fails to compile. The app builds, launches, and then throws on the first `ref.watch` or `ref.read` it reaches — often deep in a screen the developer did not open while testing. This rule turns a runtime crash into an analysis-time warning.

**See also:** [Riverpod - Getting started](https://riverpod.dev/docs/introduction/getting_started)

## Don't

```dart
void main() {
  runApp(MyApp());
}
```

## Do

```dart
void main() {
  runApp(ProviderScope(child: MyApp()));
}

// An externally-owned container is also a valid scope:
void mainWithContainer() {
  final container = ProviderContainer();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: MyApp(),
    ),
  );
}
```

## Configuration

This rule is in the **`core`** preset, so it is on with `preset: core`,
`preset: recommended` or `preset: all`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  missing_provider_scope: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
