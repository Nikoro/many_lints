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

**See also:** [Riverpod providers](https://riverpod.dev/docs/concepts2/providers)

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

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  avoid_public_notifier_properties: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  avoid_public_notifier_properties: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_notifier_constructors`](/many_lints/docs/rules/bloc-riverpod/avoid-notifier-constructors/) — Prevent initialization logic in Notifier constructors.
- [`protected_notifier_properties`](/many_lints/docs/rules/riverpod-state/protected-notifier-properties/) — A Notifier's state, ref and future should not be used from outside the notifier.
- [`notifier_build`](/many_lints/docs/rules/riverpod-state/notifier-build/) — Classes annotated with @riverpod must define a build method.
- [`avoid_bloc_public_methods`](/many_lints/docs/rules/bloc-riverpod/avoid-bloc-public-methods/) — Prevent public methods, getters, and setters in Bloc classes.
