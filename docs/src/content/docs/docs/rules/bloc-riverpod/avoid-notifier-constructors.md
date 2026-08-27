---
title: avoid_notifier_constructors
description: "Prevent initialization logic in Notifier constructors"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_notifier_constructors
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Bloc / Riverpod</span>

This rule flags a `Notifier` or `AsyncNotifier` subclass whose constructor has a non-empty body or an initializer list. A quick fix deletes the constructor.

Not reported: a constructor whose only initializer is a `super(...)` call, and a constructor with an empty body — though an empty unnamed constructor with no parameters is then reported by [`avoid_unnecessary_constructor`](/many_lints/docs/rules/code-organization/avoid-unnecessary-constructor/) instead, since Dart supplies that one for free. The fix for both is the same: delete it.

## Why use this rule

Riverpod constructs the Notifier, then calls `build()`. `ref` is not wired up until after the constructor returns, so constructor logic cannot read another provider. Worse, `build()` re-runs on every `ref.invalidate` / `ref.refresh` and on every dependency change, while the constructor does not — so anything initialized there survives a refresh that was supposed to reset it.

**See also:** [Riverpod providers](https://riverpod.dev/docs/concepts2/providers)

## Examples

### Initialization that a refresh should reset

```dart
// Don't — `_startedAt` is stamped once and never refreshed
import 'package:riverpod/riverpod.dart';

class SessionNotifier extends Notifier<Duration> {
  SessionNotifier() {                        // LINT
    _startedAt = DateTime.now();
  }

  late DateTime _startedAt;

  @override
  Duration build() => DateTime.now().difference(_startedAt);
}
```

```dart
// Do — build() re-runs on refresh, so the clock restarts with the provider
import 'package:riverpod/riverpod.dart';

class SessionNotifier extends Notifier<Duration> {
  @override
  Duration build() {
    final startedAt = DateTime.now();
    return DateTime.now().difference(startedAt);
  }
}
```

### An initializer list is flagged too

Any initializer other than `super(...)` counts, including a field initializer or an assert:

```dart
// Don't
import 'package:riverpod/riverpod.dart';

class PageNotifier extends Notifier<int> {
  PageNotifier() : _pageSize = 20;           // LINT

  final int _pageSize;

  @override
  int build() => _pageSize;
}
```

```dart
// Do — a constant belongs on the class, not in a constructor
import 'package:riverpod/riverpod.dart';

class PageNotifier extends Notifier<int> {
  static const _pageSize = 20;

  @override
  int build() => _pageSize;
}
```

### Dependencies belong to build(), not the constructor

A constructor cannot use `ref`, so an injected dependency taken there is one the Notifier can never re-read when the provider it came from changes. Read it in `build()` instead:

```dart
// Don't
import 'package:riverpod/riverpod.dart';

class ProfileNotifier extends Notifier<String> {
  ProfileNotifier(Repository repository) {   // LINT
    _repository = repository;
  }

  late Repository _repository;

  @override
  String build() => _repository.name;
}
```

```dart
// Do — `ref.watch` re-runs build() whenever the repository provider changes
import 'package:riverpod/riverpod.dart';

class ProfileNotifier extends Notifier<String> {
  @override
  String build() => ref.watch(repositoryProvider).name;
}
```

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`avoid_notifier_constructors: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_notifier_constructors: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_public_notifier_properties`](/many_lints/docs/rules/bloc-riverpod/avoid-public-notifier-properties/) — Prevent public fields, getters, and setters on Notifier classes.
- [`notifier_build`](/many_lints/docs/rules/riverpod-state/notifier-build/) — Classes annotated with @riverpod must define a build method.
- [`protected_notifier_properties`](/many_lints/docs/rules/riverpod-state/protected-notifier-properties/) — A Notifier's state, ref and future should not be used from outside the notifier.
- [`avoid_bloc_public_methods`](/many_lints/docs/rules/bloc-riverpod/avoid-bloc-public-methods/) — Prevent public methods, getters, and setters in Bloc classes.
