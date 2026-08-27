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

## Examples

### One bloc listening to another's stream

The motivating shape: `TimerBloc` wants to react when the counter changes, so it takes the `CounterBloc` and subscribes to its state stream. Now `TimerBloc` cannot be constructed or tested without a live `CounterBloc`, and the subscription outlives neither cleanly.

```dart
// Don't
import 'dart:async';

import 'package:bloc/bloc.dart';

sealed class CounterEvent {}

class Increment extends CounterEvent {}

sealed class TimerEvent {}

class CounterChanged extends TimerEvent {
  CounterChanged(this.value);

  final int value;
}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
  }
}

class TimerBloc extends Bloc<TimerEvent, int> {
  TimerBloc(this.counterBloc) : super(0) {          // LINT on `counterBloc`
    on<CounterChanged>((event, emit) => emit(event.value));
    _subscription = counterBloc.stream.listen((v) => add(CounterChanged(v)));
  }

  final CounterBloc counterBloc;

  late final StreamSubscription<int> _subscription;

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
```

Put the shared data in a repository both blocs read, and let each own its own subscription to it:

```dart
// Do
import 'dart:async';

import 'package:bloc/bloc.dart';

sealed class CounterEvent {}

class Increment extends CounterEvent {}

sealed class TimerEvent {}

class CounterChanged extends TimerEvent {
  CounterChanged(this.value);

  final int value;
}

class CounterRepository {
  final _controller = StreamController<int>.broadcast();

  Stream<int> get changes => _controller.stream;

  int value = 0;

  void increment() => _controller.add(++value);
}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc(this.repository) : super(0) {
    on<Increment>((event, emit) {
      repository.increment();
      emit(repository.value);
    });
  }

  final CounterRepository repository;
}

class TimerBloc extends Bloc<TimerEvent, int> {
  TimerBloc(this.repository) : super(0) {
    on<CounterChanged>((event, emit) => emit(event.value));
    _subscription = repository.changes.listen((v) => add(CounterChanged(v)));
  }

  final CounterRepository repository;

  late final StreamSubscription<int> _subscription;

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
```

### Cubits count too, in both directions

The rule matches any constructor parameter assignable to `BlocBase` — so a Cubit taking a Bloc, a Bloc taking a Cubit, and a named parameter are all reported:

```dart
// Don't
import 'package:bloc/bloc.dart';

sealed class CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0);
}

class SettingsCubit extends Cubit<bool> {
  SettingsCubit() : super(false);
}

class SummaryCubit extends Cubit<int> {
  SummaryCubit(this.counterBloc) : super(0);        // LINT on `counterBloc`

  final CounterBloc counterBloc;
}

class ReportCubit extends Cubit<int> {
  ReportCubit({required this.settings}) : super(0); // LINT on `settings`

  final SettingsCubit settings;
}
```

### Coordinate in the widget layer instead

When the interaction is one-off rather than continuous, do not wire the blocs together at all — let the widget that already has both read one and dispatch to the other:

```dart
// Do
BlocListener<CounterBloc, int>(
  listener: (context, count) {
    context.read<TimerBloc>().add(CounterChanged(count));
  },
  child: const TimerView(),
)
```

## Known limitations

Only constructor parameters are checked. A bloc that reaches another one through a service locator inside its body (`getIt<CounterBloc>()`) has the same coupling but is invisible to this rule — there is no parameter to type-check.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  avoid_passing_bloc_to_bloc: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  avoid_passing_bloc_to_bloc: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_bloc_public_methods`](/many_lints/docs/rules/bloc-riverpod/avoid-bloc-public-methods/) — Prevent public methods, getters, and setters in Bloc classes.
- [`prefer_bloc_extensions`](/many_lints/docs/rules/bloc-riverpod/prefer-bloc-extensions/) — Use context.read/watch instead of BlocProvider.of or RepositoryProvider.of.
- [`avoid_duplicate_bloc_event_handlers`](/many_lints/docs/rules/bloc-riverpod/avoid-duplicate-bloc-event-handlers/) — Register each bloc event type exactly once.
- [`avoid_passing_build_context_to_blocs`](/many_lints/docs/rules/bloc-riverpod/avoid-passing-build-context-to-blocs/) — Prevent passing BuildContext to Bloc or Cubit classes.
