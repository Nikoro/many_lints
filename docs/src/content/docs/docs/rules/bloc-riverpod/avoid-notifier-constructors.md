---
title: avoid_notifier_constructors
description: "Prevent initialization logic in Notifier constructors"
sidebar:
  label: avoid_notifier_constructors
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Bloc / Riverpod</span>

This rule flags `Notifier` and `AsyncNotifier` subclasses that have constructors with non-empty bodies or initializer lists. Empty constructors are allowed. All initialization logic should go into the `build()` method instead.

## Why use this rule

Riverpod creates and recreates Notifiers as part of its lifecycle management. The `build()` method is the proper place for initialization because it runs at the right time in the provider lifecycle and has access to `ref`. Constructor logic runs before the Notifier is fully wired up, which means you can't use `ref` there, and the logic won't re-run when the provider is refreshed or invalidated.

**See also:** [Riverpod Notifier documentation](https://riverpod.dev/docs/concepts/providers#notifierprovider)

## Don't

```dart
import 'package:riverpod/riverpod.dart';

// Constructor with body
class BadCounter extends Notifier<int> {
  var _initial = 0;

  BadCounter() {
    _initial = 1;
  }

  @override
  int build() => _initial;
}

// Constructor with initializer list
class BadCounter2 extends Notifier<int> {
  final int _initial;

  BadCounter2() : _initial = 1;

  @override
  int build() => _initial;
}
```

## Do

```dart
import 'package:riverpod/riverpod.dart';

// No constructor, initialization in build()
class GoodCounter extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
}

// Empty constructor is fine
class GoodCounter2 extends Notifier<int> {
  GoodCounter2();

  @override
  int build() => 0;
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_notifier_constructors: false
```
