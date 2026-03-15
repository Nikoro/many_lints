---
title: avoid_unnecessary_consumer_widgets
description: "Don't extend ConsumerWidget if you never use WidgetRef"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_unnecessary_consumer_widgets
---

<span class="rule-badge rule-badge--version">v0.1.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

This rule detects `ConsumerWidget` subclasses where the `WidgetRef` parameter is never used inside the `build` method. If you are not reading or watching any providers, there is no reason to use `ConsumerWidget` over a plain `StatelessWidget`.

## Why use this rule

Every `ConsumerWidget` subscribes to the Riverpod container, which means it participates in the provider dependency graph even when it does not need to. Switching to `StatelessWidget` removes that overhead, makes the widget's dependencies explicit (it has none), and signals to other developers that this widget is purely presentational.

**See also:** [ConsumerWidget](https://riverpod.dev/docs/essentials/combining_requests)

## Don't

```dart
// ConsumerWidget with unused ref parameter
class Greeting extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref is never used
    return Text('Hello');
  }
}
```

## Do

```dart
// StatelessWidget since no providers are needed
class Greeting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('Hello');
  }
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_unnecessary_consumer_widgets: false
```
