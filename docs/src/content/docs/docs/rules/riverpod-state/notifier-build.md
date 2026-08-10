---
title: notifier_build
description: "Classes annotated with @riverpod must define a build method."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: notifier_build
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Riverpod State</span>

Flags a class annotated with `@riverpod` (or `@Riverpod(...)`) that has no `build` method.

## Why use this rule

The generator turns a notifier's `build` method into the provider's create function. Without one, the build step fails — and the error points at the generated file, not the class that caused it. Catching this at analysis time names the actual class and offers a stub.

**See also:** [Riverpod - Code generation](https://riverpod.dev/docs/concepts2/about_code_generation)

## Don't

```dart
@riverpod
class Counter extends _$Counter {} // LINT
```

## Do

```dart
@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;
}
```

Functional providers are not affected — they have no `build` method by design:

```dart
@riverpod
int counter(Ref ref) => 0;
```

## Configuration

This rule is in the **`core`** preset, so it is on with `preset: core`,
`preset: recommended` or `preset: all`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  notifier_build: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
