---
title: provider_parameters
description: "Family provider arguments must have stable equality, or the provider is recreated on every rebuild."
sidebar:
  label: provider_parameters
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Riverpod State</span>

Flags an argument passed to a family provider that has no stable equality — a non-const collection literal, a closure, or an instance of a class that does not override `==`.

## Why use this rule

Riverpod caches one provider instance per family argument, keyed by `==`. An argument that allocates a new object on every build never compares equal to the previous one, so Riverpod treats each rebuild as a brand-new provider: the old one is disposed, state is lost, and any network request behind it runs again. The symptom is an infinite rebuild loop or a widget that never keeps its data — both hard to trace back to the argument.

**See also:** [Riverpod families](https://riverpod.dev/docs/concepts2/family)

## Don't

```dart
// A new list every build — never equal to the last one
ref.watch(myProvider([1, 2, 3]));

// A new closure every build
ref.watch(myProvider(() => 42));

// Foo does not override ==, so each instance is distinct
ref.watch(myProvider(Foo()));
```

## Do

```dart
class Foo {
  const Foo(this.id);
  final int id;

  @override
  bool operator ==(Object other) => other is Foo && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

void watchStableValues(WidgetRef ref) {
  // Const values are canonicalized, so equality holds.
  ref.watch(myProvider(const [1, 2, 3]));
  ref.watch(myProvider(const Foo(1)));

  // Primitives compare by value.
  ref.watch(myProvider(42));
}
```

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`provider_parameters: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  provider_parameters: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`missing_provider_scope`](/many_lints/docs/rules/riverpod-state/missing-provider-scope/) — Flutter applications using Riverpod must have a ProviderScope at the root of the widget tree.
- [`async_value_nullable_pattern`](/many_lints/docs/rules/riverpod-state/async-value-nullable-pattern/) — Matching AsyncValue(:final value?) on a nullable value hides a legitimate null result.
- [`avoid_build_context_in_providers`](/many_lints/docs/rules/riverpod-state/avoid-build-context-in-providers/) — Providers outlive widgets, so they should not receive a BuildContext.
- [`avoid_ref_inside_state_dispose`](/many_lints/docs/rules/riverpod-state/avoid-ref-inside-state-dispose/) — Avoid accessing ref inside the dispose method of a ConsumerState.
