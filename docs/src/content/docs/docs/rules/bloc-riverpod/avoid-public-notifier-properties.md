---
title: avoid_public_notifier_properties
description: "Prevent public fields, getters, and setters on Notifier classes"
sidebar:
  label: avoid_public_notifier_properties
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Bloc / Riverpod</span>

This rule flags public **mutable** properties (fields, getters, and setters) on `Notifier` and `AsyncNotifier` subclasses.

Not reported: the built-in `state`, `final` and `const` fields, public methods, private and static properties, and anything marked `@override`, `@protected`, `@visibleForOverriding` or `@visibleForTesting`. So `final Logger logger;` on a notifier is left alone — only state a caller can reassign is the target.

## Why use this rule

A Notifier's contract is one reactive value: `state`. A widget that reads `ref.watch(myProvider)` is rebuilt when `state` changes and at no other time. A second public property is read *outside* that channel — the widget gets whatever the field held at build time and is never told when it changes, so the screen quietly shows a stale value.

**See also:** [Riverpod providers](https://riverpod.dev/docs/concepts2/providers)

## Examples

### A second field the UI never sees change

`isLoading` is set, no rebuild is scheduled, and the spinner never appears:

```dart
// Don't
import 'package:riverpod/riverpod.dart';

class SearchNotifier extends Notifier<List<String>> {
  bool isLoading = false;                    // LINT

  @override
  List<String> build() => const [];

  Future<void> search(String query) async {
    isLoading = true;                        // no rebuild — nothing watches this
    state = await _fetch(query);
    isLoading = false;
  }

  Future<List<String>> _fetch(String query) async => [query];
}
```

Fold it into the state so one `ref.watch` sees both:

```dart
// Do
import 'package:riverpod/riverpod.dart';

class SearchState {
  const SearchState({required this.results, required this.isLoading});

  final List<String> results;
  final bool isLoading;
}

class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() =>
      const SearchState(results: [], isLoading: false);

  Future<void> search(String query) async {
    state = SearchState(results: state.results, isLoading: true);
    state = SearchState(results: await _fetch(query), isLoading: false);
  }

  Future<List<String>> _fetch(String query) async => [query];
}
```

### Getters and setters count as properties

Any public getter or setter other than `state` is reported, however trivial:

```dart
// Don't
import 'package:riverpod/riverpod.dart';

class CartNotifier extends Notifier<List<String>> {
  int get itemCount => state.length;         // LINT
  set discount(double value) => _discount = value;   // LINT

  double _discount = 0;

  @override
  List<String> build() => const [];
}
```

A derived value belongs on the state class, or in its own provider:

```dart
// Do
import 'package:riverpod/riverpod.dart';

class CartNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => const [];
}

final itemCountProvider =
    Provider<int>((ref) => ref.watch(cartProvider).length);
```

### What is left alone

Methods, private members, statics, and anything a caller cannot reassign or is deliberately narrowed:

```dart
import 'package:meta/meta.dart';
import 'package:riverpod/riverpod.dart';

class OrderNotifier extends Notifier<int> {
  // Not reported: a `final` field is injected collaboration, not leaked state
  final Logger logger = Logger();

  // Not reported: private
  int _retries = 0;

  // Not reported: static
  static const maxRetries = 3;

  // Not reported: methods are how a Notifier is meant to be driven
  void submit() => state++;

  // Not reported: deliberately exposed to a narrower audience
  @visibleForTesting
  int get retries => _retries;

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
