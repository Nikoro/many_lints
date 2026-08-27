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

A widget reaching into the notifier for the current value. It compiles, renders
the right number once, and then never updates — `notifier.state` is a plain
field read, not a subscription:

```dart
class CartNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void add() => state = state + 1;
}

final cartProvider = NotifierProvider<CartNotifier, int>(CartNotifier.new);

class CartBadge extends ConsumerWidget {
  const CartBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(cartProvider.notifier);
    return Text('${notifier.state}'); // LINT
  }
}
```

Writing it from outside is worse: the transition happens somewhere no reader of
`CartNotifier` will look for it.

```dart
void resetCart(WidgetRef ref) {
  ref.read(cartProvider.notifier).state = 0; // LINT
}
```

## Do

Read the value through the provider, so the widget is subscribed:

```dart
class CartBadge extends ConsumerWidget {
  const CartBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartProvider);
    return Text('$count');
  }
}
```

Mutate through a method the notifier exposes, so every transition lives in the
notifier:

```dart
class CartNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void add() => state = state + 1;

  void reset() => state = 0;
}

void resetCart(WidgetRef ref) {
  ref.read(cartProvider.notifier).reset();
}
```

Inside the notifier itself the members are free to use — that is what they are
for:

```dart
class CartNotifier extends Notifier<int> {
  @override
  int build() => 0;

  Future<void> syncFromServer() async {
    final remote = await ref.read(apiProvider).fetchCartCount();
    state = remote;
  }
}
```

## Known limitations

The exemption is exact: access is allowed when the target's type is the very
class the code sits in. A helper mixin on the notifier, or a subclass reading
`super`'s `state` through a differently-typed variable, is still reported.

Reads through a variable whose type is not resolved are not reported, since the
rule matches the receiver by resolved type rather than by name.

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
