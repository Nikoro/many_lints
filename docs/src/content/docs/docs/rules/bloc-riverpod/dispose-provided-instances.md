---
title: dispose_provided_instances
description: "Ensure disposable instances in Riverpod providers are cleaned up with ref.onDispose"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: dispose_provided_instances
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Bloc / Riverpod</span>

This rule flags instances created inside Riverpod provider callbacks or Notifier `build()` methods that have a `dispose()`, `close()`, or `cancel()` method but are not cleaned up via `ref.onDispose()`. It recognizes tear-off, lambda, and block body cleanup patterns.

## Why use this rule

When a provider creates a disposable resource (like a controller, stream subscription, or service with a `close()` method) without registering cleanup, the resource leaks when the provider is destroyed. This leads to memory leaks and resource exhaustion over time. The `ref.onDispose()` callback ensures proper cleanup regardless of how or when the provider is disposed.

**See also:** [Riverpod automatic disposal](https://riverpod.dev/docs/concepts2/auto_dispose)

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

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

### Options

Configure in `many_lints.yaml` at your package root:

```yaml
rules:
  dispose_provided_instances:
    additional_cleanup_methods: [release, shutdown]
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `cleanup_methods` | list of strings | `[dispose, close, cancel]` | **Replaces** the cleanup method names the rule looks for |
| `additional_cleanup_methods` | list of strings | `[]` | **Extends** whichever list applies |

Order matters: it is the priority used when a type declares more than one
cleanup method. Names added via `additional_cleanup_methods` are appended, so a
project's own `release()` is only chosen when the type declares no standard
cleanup method.

Both options apply to detection *and* recognition — a method listed here counts
both as "this instance needs disposing" and as "this `ref.onDispose` disposes it".

Alternatively, use a top-level `many_lints:` section in `analysis_options.yaml`.
Note this section does **not** inherit through `include:`; when both sources
exist, `many_lints.yaml` wins and the section is ignored entirely.
