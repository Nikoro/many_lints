---
title: avoid_bloc_public_methods
description: "Avoid declaring public members in Bloc classes. Use events via 'add' instead."
sidebar:
  label: avoid_bloc_public_methods
---

| Property | Value |
|----------|-------|
| **Rule name** | `avoid_bloc_public_methods` |
| **Category** | Bloc / Riverpod |
| **Severity** | Warning |
| **Has quick fix** | No |

## Problem

Avoid declaring public members in Bloc classes. Use events via 'add' instead.

## Suggestion

Make this member private or trigger state changes through events.

## Example

```dart
import 'package:bloc/bloc.dart';

// avoid_bloc_public_methods
//
// Blocs should not declare public methods, getters, or setters.
// State changes should be triggered through events via the `add` method.

abstract class CounterEvent {}

class Increment extends CounterEvent {}

class Decrement extends CounterEvent {}

// ❌ Bad: Public methods in a Bloc class
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
    on<Decrement>((event, emit) => emit(state - 1));
  }

  // LINT: Avoid declaring public methods in Bloc classes
  void increment() {}

  // LINT: Avoid declaring public getters in Bloc classes
  int get currentValue => state;

  // LINT: Avoid declaring public setters in Bloc classes
  set currentValue(int value) {}
}

// ✅ Good: Only private members and overrides
class GoodCounterBloc extends Bloc<CounterEvent, int> {
  GoodCounterBloc() : super(0) {
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
