---
title: prefer_immutable_bloc_state
description: "Ensure Bloc and Cubit state classes are annotated with @immutable"
sidebar:
  label: prefer_immutable_bloc_state
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Bloc / Riverpod</span>

This rule flags Bloc and Cubit state classes that are missing the `@immutable` annotation. It detects state classes both by type parameter analysis (classes used as the state type in `Bloc<Event, State>` or `Cubit<State>`) and by naming convention (classes ending with `State`), including their subclasses.

## Why use this rule

Mutable state objects are a common source of subtle bugs in the Bloc pattern. If you mutate a state object in place instead of creating a new one, `emit` won't trigger a rebuild because Bloc compares state by reference equality. Marking state classes as `@immutable` signals this intent and enables analyzer warnings when you accidentally add mutable fields.

**See also:** [Bloc state management](https://bloclibrary.dev/bloc-concepts/#state)

## Don't

```dart
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

abstract class CounterEvent {}

// Missing @immutable annotation
sealed class CounterState {}

class CounterInitial extends CounterState {}

class CounterLoaded extends CounterState {
  final int count;
  CounterLoaded(this.count);
}

class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(CounterInitial());
}
```

## Do

```dart
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

abstract class CounterEvent {}

@immutable
sealed class CounterState {}

@immutable
class CounterInitial extends CounterState {}

@immutable
class CounterLoaded extends CounterState {
  final int count;
  CounterLoaded(this.count);
}

class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(CounterInitial());
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_immutable_bloc_state: false
```
