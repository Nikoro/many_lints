---
title: use_bloc_suffix
description: "Ensure classes extending Bloc have the Bloc suffix"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: use_bloc_suffix
---

<span class="rule-badge rule-badge--version">v0.1.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Class Naming</span>

This rule flags classes that extend `Bloc` but don't include the `Bloc` suffix in their name. Consistent naming makes it immediately clear which classes are Blocs when scanning through code or reading imports.

## Why use this rule

When a class extends `Bloc` but is named something like `CounterManager` or `AuthHandler`, other developers have to check the inheritance chain to understand what it is. The `Bloc` suffix is a widely adopted convention in the Flutter/Bloc ecosystem that makes the architectural role of each class obvious at a glance.

**See also:** [Bloc naming conventions](https://bloclibrary.dev/naming-conventions/)

## Don't

```dart
import 'package:bloc/bloc.dart';

abstract class CounterEvent {}

class Increment extends CounterEvent {}

// Missing 'Bloc' suffix
class CounterManager extends Bloc<CounterEvent, int> {
  CounterManager() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
  }
}
```

## Do

```dart
import 'package:bloc/bloc.dart';

abstract class CounterEvent {}

class Increment extends CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
  }
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      use_bloc_suffix: false
```
