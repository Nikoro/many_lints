---
title: dispose_provided_instances
description: "Instance '{0}' has a dispose method but is not disposed via ref.onDispose()."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: dispose_provided_instances
---

| Property | Value |
|----------|-------|
| **Rule name** | `dispose_provided_instances` |
| **Category** | Bloc / Riverpod |
| **Severity** | Warning |
| **Has quick fix** | Yes |

## Problem

Instance '{0}' has a dispose method but is not disposed via ref.onDispose().

## Suggestion

Add 'ref.onDispose({0}.dispose)' to ensure proper resource cleanup.

## Example

```dart
// ignore_for_file: unused_local_variable

// dispose_provided_instances
//
// Warns when an instance with a dispose/close/cancel method is created
// inside a Riverpod provider callback or Notifier build() method without
// a corresponding ref.onDispose() call to clean it up.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';

class DisposableService {
  void dispose() {}
  String get value => 'hello';
}

class CloseableService {
  void close() {}
}

// ❌ Bad: Instance has dispose() but ref.onDispose is not called
final badProvider = Provider<DisposableService>((ref) {
  // LINT: instance has a dispose method but is not disposed via ref.onDispose()
  final instance = DisposableService();
  return instance;
});

// ❌ Bad: Instance has close() but ref.onDispose is not called
final badCloseProvider = Provider.autoDispose<CloseableService>((ref) {
  // LINT: service has a dispose method but is not disposed via ref.onDispose()
  final service = CloseableService();
  return service;
});

// ❌ Bad: Notifier build() creates disposable without ref.onDispose
class BadNotifier extends Notifier<DisposableService> {
  @override
  DisposableService build() {
    // LINT: instance has a dispose method but is not disposed via ref.onDispose()
    final instance = DisposableService();
    return instance;
  }
}

// ✅ Good: Using ref.onDispose with tear-off
final goodProvider = Provider<DisposableService>((ref) {
  final instance = DisposableService();
  ref.onDispose(instance.dispose);
  return instance;
});

// ✅ Good: Using ref.onDispose with lambda
final goodLambdaProvider = Provider<DisposableService>((ref) {
  final instance = DisposableService();
  ref.onDispose(() => instance.dispose());
  return instance;
});

// ✅ Good: Using ref.onDispose with block body
final goodBlockProvider = Provider<DisposableService>((ref) {
  final instance = DisposableService();
  ref.onDispose(() {
    instance.dispose();
  });
  return instance;
});

// ✅ Good: Notifier build() with ref.onDispose
class GoodNotifier extends Notifier<DisposableService> {
  @override
  DisposableService build() {
    final instance = DisposableService();
    ref.onDispose(instance.dispose);
    return instance;
  }
}

// ✅ Good: Non-disposable instance (no dispose/close/cancel methods)
class RegularService {
  void doSomething() {}
}

final regularProvider = Provider<RegularService>((ref) {
  final instance = RegularService();
  return instance;
});
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      dispose_provided_instances: false
```
