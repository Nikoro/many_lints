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
// Const values are canonicalized, so equality holds
ref.watch(myProvider(const [1, 2, 3]));
ref.watch(myProvider(const Foo()));

// Primitives compare by value
ref.watch(myProvider(42));

// A class with a real == is stable across rebuilds
class Foo {
  Foo(this.id);
  final int id;

  @override
  bool operator ==(Object other) => other is Foo && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

ref.watch(myProvider(Foo(1)));
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      provider_parameters: false
```
