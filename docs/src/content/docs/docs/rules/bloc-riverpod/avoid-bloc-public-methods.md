---
title: avoid_bloc_public_methods
description: "Prevent public methods, getters, and setters in Bloc classes"
sidebar:
  label: avoid_bloc_public_methods
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Bloc / Riverpod</span>

This rule flags public methods, getters, and setters declared in Bloc classes (but not Cubits). Blocs should only expose state changes through events via the `add` method, not through custom public members.

## Why use this rule

The whole point of the Bloc pattern is that state changes are driven by events. When you add public methods like `increment()` or `reset()` to a Bloc, you bypass the event-driven architecture and lose the ability to trace, replay, and log state transitions. If you need public methods, you probably want a Cubit instead. Private members, overrides, and static members are all allowed.

**See also:** [Bloc best practices](https://bloclibrary.dev/bloc-concepts/) | [When to use Cubit vs Bloc](https://bloclibrary.dev/bloc-concepts/#cubit-vs-bloc)

## Don't

```dart
import 'package:bloc/bloc.dart';

abstract class CounterEvent {}

class Increment extends CounterEvent {}

class Decrement extends CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
    on<Decrement>((event, emit) => emit(state - 1));
  }

  // Public method bypasses event-driven pattern
  void increment() {}

  // Public getter exposes internal state
  int get currentValue => state;

  // Public setter allows direct mutation
  set currentValue(int value) {}
}
```

## Do

```dart
import 'package:bloc/bloc.dart';

abstract class CounterEvent {}

class Increment extends CounterEvent {}

class Decrement extends CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
    on<Decrement>((event, emit) => emit(state - 1));
  }

  // Private methods are fine
  void _handleReset() {}

  // Overrides are fine
  @override
  void onChange(Change<int> change) {
    super.onChange(change);
  }

  // Static methods are fine
  static CounterEvent createIncrement() => Increment();
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_bloc_public_methods: false
```
