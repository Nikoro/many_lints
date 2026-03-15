---
title: avoid_public_notifier_properties
description: "Prevent public fields, getters, and setters on Notifier classes"
sidebar:
  label: avoid_public_notifier_properties
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Bloc / Riverpod</span>

This rule flags public properties (fields, getters, and setters) on `Notifier` and `AsyncNotifier` subclasses, except for the built-in `state` property. Public methods, private properties, static properties, and overrides are all allowed.

## Why use this rule

Riverpod Notifiers are designed to expose a single reactive `state` property. When you add extra public getters or fields, consumers can read stale values that don't trigger rebuilds, leading to UI inconsistencies. Instead, consolidate all data into a model class used as the `state` type. This keeps the reactive contract intact and makes state changes predictable.

**See also:** [Riverpod Notifier documentation](https://riverpod.dev/docs/concepts/providers#notifierprovider)

## Don't

```dart
import 'package:riverpod/riverpod.dart';

// Public getter exposes state outside the reactive `state` property
class BadNotifier extends Notifier<int> {
  int get publicGetter => 0;

  @override
  int build() => 0;
}

// Public field on a Notifier
class BadNotifier2 extends Notifier<int> {
  int publicField = 0;

  @override
  int build() => 0;
}

// Public setter on a Notifier
class BadNotifier3 extends Notifier<int> {
  int _value = 0;

  set publicSetter(int value) => _value = value;

  @override
  int build() => _value;
}
```

## Do

```dart
import 'package:riverpod/riverpod.dart';

// Consolidate state into a model class
class MyState {
  final int left;
  final int right;
  MyState(this.left, this.right);
}

class GoodNotifier extends Notifier<MyState> {
  @override
  MyState build() => MyState(0, 1);
}

// Private properties are fine
class GoodNotifier2 extends Notifier<int> {
  int _privateField = 0;
  int get _privateGetter => _privateField;

  @override
  int build() => _privateGetter;
}

// Public methods are allowed (only properties are flagged)
class GoodNotifier3 extends Notifier<int> {
  void increment() => state++;

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
      avoid_public_notifier_properties: false
```
