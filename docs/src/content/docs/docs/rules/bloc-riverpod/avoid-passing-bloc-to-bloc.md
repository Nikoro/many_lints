---
title: avoid_passing_bloc_to_bloc
description: "Prevent Bloc/Cubit classes from depending on other Bloc/Cubit instances"
sidebar:
  label: avoid_passing_bloc_to_bloc
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Bloc / Riverpod</span>

This rule flags Bloc or Cubit classes that accept another Bloc or Cubit as a constructor parameter. Direct bloc-to-bloc dependencies create tight coupling and break the layered architecture that Bloc is designed around.

## Why use this rule

When one Bloc depends directly on another, you create a hidden coupling that makes both harder to test, reuse, and reason about. State changes should flow through the presentation layer (where widgets coordinate between Blocs) or through shared repositories in the domain layer. Direct dependencies also make it easy to introduce circular references and lifecycle issues.

**See also:** [Bloc architecture](https://bloclibrary.dev/architecture/)

## Don't

```dart
import 'package:bloc/bloc.dart';

abstract class CounterEvent {}

class Increment extends CounterEvent {}

abstract class TimerEvent {}

// Bloc depends on another Bloc
class TimerBloc extends Bloc<TimerEvent, int> {
  final CounterBloc counterBloc;

  TimerBloc(this.counterBloc) : super(0);
}

// Cubit depends on a Bloc
class SummaryCubit extends Cubit<int> {
  final CounterBloc counterBloc;

  SummaryCubit(this.counterBloc) : super(0);
}
```

## Do

```dart
import 'package:bloc/bloc.dart';

abstract class CounterEvent {}

class Increment extends CounterEvent {}

abstract class TimerEvent {}

// Depend on a repository instead
class CounterRepository {
  int getValue() => 0;
}

class CounterBloc extends Bloc<CounterEvent, int> {
  final CounterRepository repository;

  CounterBloc(this.repository) : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
  }
}

// No external Bloc dependencies
class IndependentBloc extends Bloc<TimerEvent, int> {
  IndependentBloc() : super(0);
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_passing_bloc_to_bloc: false
```
