---
title: dispose_provided_instances
description: "Ensure disposable instances in Riverpod providers are cleaned up with ref.onDispose"
sidebar:
  label: dispose_provided_instances
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Bloc / Riverpod</span>

This rule flags instances created inside Riverpod provider callbacks or Notifier `build()` methods that have a `dispose()`, `close()`, or `cancel()` method but are not cleaned up via `ref.onDispose()`. It recognizes tear-off, lambda, and block body cleanup patterns.

## Why use this rule

When a provider creates a disposable resource (like a controller, stream subscription, or service with a `close()` method) without registering cleanup, the resource leaks when the provider is destroyed. This leads to memory leaks and resource exhaustion over time. The `ref.onDispose()` callback ensures proper cleanup regardless of how or when the provider is disposed.

**See also:** [Riverpod ref.onDispose](https://riverpod.dev/docs/concepts/modifiers/auto_dispose)

## Don't

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
  String get value => 'hello';
}

// Instance has dispose() but ref.onDispose is not called
final badProvider = Provider<DisposableService>((ref) {
  final instance = DisposableService();
  return instance;
});

// Notifier build() creates disposable without ref.onDispose
class BadNotifier extends Notifier<DisposableService> {
  @override
  DisposableService build() {
    final instance = DisposableService();
    return instance;
  }
}
```

## Do

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
  String get value => 'hello';
}

// Using ref.onDispose with tear-off
final goodProvider = Provider<DisposableService>((ref) {
  final instance = DisposableService();
  ref.onDispose(instance.dispose);
  return instance;
});

// Using ref.onDispose with lambda
final goodLambdaProvider = Provider<DisposableService>((ref) {
  final instance = DisposableService();
  ref.onDispose(() => instance.dispose());
  return instance;
});

// Notifier build() with ref.onDispose
class GoodNotifier extends Notifier<DisposableService> {
  @override
  DisposableService build() {
    final instance = DisposableService();
    ref.onDispose(instance.dispose);
    return instance;
  }
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      dispose_provided_instances: false
```
