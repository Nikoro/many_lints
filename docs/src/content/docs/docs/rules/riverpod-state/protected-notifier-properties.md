---
title: protected_notifier_properties
description: "A Notifier's state, ref and future should not be used from outside the notifier."
sidebar:
  label: protected_notifier_properties
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Riverpod State</span>

Flags access to `state`, `stateOrNull`, `future` or `ref` on a `Notifier` from outside the notifier that owns them. These members are part of a notifier's internal API.

## Why use this rule

Reading `notifier.state` bypasses the provider system: the value is read once, and the reader is never rebuilt when it changes. Writing it from outside moves state transitions out of the notifier, which is where the rest of the codebase expects to find them. Going through the provider gives correct reactivity and keeps mutations in one place.

**See also:** [Riverpod providers](https://riverpod.dev/docs/concepts2/providers)

## Don't

```dart
void bad(MyNotifier notifier) {
  print(notifier.state);   // LINT
  notifier.state = 1;      // LINT
  print(notifier.ref);     // LINT
}
```

## Do

```dart
// Read the value through its provider so the widget rebuilds on change.
Widget good(WidgetRef ref) {
  final value = ref.watch(myProvider);
  return Text('$value');
}

// Mutate through a method the notifier exposes.
void increment(WidgetRef ref) {
  ref.read(myProvider.notifier).increment();
}

// Inside the notifier itself, the members are free to use.
class MyNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state = state + 1;
}
```

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  protected_notifier_properties: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  protected_notifier_properties: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`notifier_build`](/many_lints/docs/rules/riverpod-state/notifier-build/) — Classes annotated with @riverpod must define a build method.
- [`avoid_public_notifier_properties`](/many_lints/docs/rules/bloc-riverpod/avoid-public-notifier-properties/) — Prevent public fields, getters, and setters on Notifier classes.
- [`avoid_notifier_constructors`](/many_lints/docs/rules/bloc-riverpod/avoid-notifier-constructors/) — Prevent initialization logic in Notifier constructors.
- [`async_value_nullable_pattern`](/many_lints/docs/rules/riverpod-state/async-value-nullable-pattern/) — Matching AsyncValue(:final value?) on a nullable value hides a legitimate null result.
