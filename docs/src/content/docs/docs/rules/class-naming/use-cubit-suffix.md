---
title: use_cubit_suffix
description: "Ensure classes extending Cubit have the Cubit suffix"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: use_cubit_suffix
---

<span class="rule-badge rule-badge--version">v0.1.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Class Naming</span>

This rule flags classes that extend `Cubit` but don't include the `Cubit` suffix in their name. Consistent naming makes it immediately clear which classes are Cubits when scanning through code or reading imports.

## Why use this rule

When a class extends `Cubit` but is named something generic like `Counter` or `AuthManager`, it becomes unclear whether it's a Cubit, a plain class, or some other state holder. The `Cubit` suffix is a standard convention in the Bloc ecosystem that communicates intent instantly.

**See also:** [Bloc naming conventions](https://bloclibrary.dev/naming-conventions/)

## Don't

```dart
import 'package:bloc/bloc.dart';

// Missing 'Cubit' suffix
class Counter extends Cubit<int> {
  Counter() : super(0);

  void increment() => emit(state + 1);
}
```

## Do

```dart
import 'package:bloc/bloc.dart';

class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      use_cubit_suffix: false
```
