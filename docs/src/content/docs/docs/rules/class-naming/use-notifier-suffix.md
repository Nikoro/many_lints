---
title: use_notifier_suffix
description: "Ensure classes extending Notifier have the Notifier suffix"
sidebar:
  label: use_notifier_suffix
---

<span class="rule-badge rule-badge--version">v0.1.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Class Naming</span>

This rule flags classes that extend `Notifier` (or `AsyncNotifier`) but don't include the `Notifier` suffix in their name. Consistent naming makes it immediately clear which classes are Riverpod Notifiers when scanning through your codebase.

## Why use this rule

Riverpod Notifiers have a specific lifecycle and behavior -- they're created by providers, have a `build()` method, and manage reactive state. When a class like `CounterManager` extends `Notifier` without the suffix, developers have to inspect the class to understand its role. The `Notifier` suffix makes the architectural intent obvious.

**See also:** [Riverpod Notifier documentation](https://riverpod.dev/docs/concepts/providers#notifierprovider)

## Don't

```dart
import 'package:riverpod/riverpod.dart';

// Missing 'Notifier' suffix
class CounterManager extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
}
```

## Do

```dart
import 'package:riverpod/riverpod.dart';

class CounterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      use_notifier_suffix: false
```
