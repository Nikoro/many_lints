---
title: avoid_bloc_public_methods
description: "Prevent public methods, getters, and setters in Bloc classes"
sidebar:
  label: avoid_bloc_public_methods
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Bloc / Riverpod</span>

This rule flags public methods, getters, and setters declared on a `Bloc`. Cubits are exempt — a Cubit's public methods *are* its API.

Not reported: private members, `static` members, and anything marked `@override`.

## Why use this rule

A Bloc's whole point is that every state change enters through `add(event)`, where it can be logged, replayed and observed by `BlocObserver`. A public method is a second, untracked entrance: it changes state without producing an event, so the transition never appears in the observer log and cannot be reproduced from a recorded event sequence.

If the class genuinely wants a method-shaped API, it wants to be a Cubit — that is exactly the difference between the two.

**See also:** [Bloc best practices](https://bloclibrary.dev/bloc-concepts/) | [When to use Cubit vs Bloc](https://bloclibrary.dev/bloc-concepts/#cubit-vs-bloc)

## Examples

### A convenience method that bypasses the event log

The method works, but `BlocObserver.onEvent` never fires for it, so the transition is invisible to logging and to replay:

```dart
// Don't
import 'package:bloc/bloc.dart';

sealed class CounterEvent {}

class Increment extends CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
  }

  // LINT — changes state without an event
  void increment() => emit(state + 1);
}
```

Add the event instead. The caller writes one more character and gets the whole observer pipeline:

```dart
// Do
import 'package:bloc/bloc.dart';

sealed class CounterEvent {}

class Increment extends CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
  }
}

// At the call site: counterBloc.add(Increment());
```

### A getter that duplicates the state

`isEmpty` reads fine, but a widget calling it is not subscribed to anything, so it never rebuilds when the answer changes:

```dart
// Don't
import 'package:bloc/bloc.dart';

sealed class CartEvent {}

class CartBloc extends Bloc<CartEvent, List<String>> {
  CartBloc() : super(const []);

  bool get isEmpty => state.isEmpty;         // LINT
}
```

```dart
// Do — derive it where the state is already being watched
import 'package:bloc/bloc.dart';

sealed class CartEvent {}

class CartBloc extends Bloc<CartEvent, List<String>> {
  CartBloc() : super(const []);
}

// In the widget:
// final isEmpty = context.watch<CartBloc>().state.isEmpty;
```

### Cubits are not reported

The same members on a Cubit are exactly right — that is what a Cubit is for:

```dart
// Not reported
import 'package:bloc/bloc.dart';

class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);

  void reset() => emit(0);
}
```

### Overrides, privates and statics are allowed

```dart
import 'package:bloc/bloc.dart';

sealed class CounterEvent {}

class Increment extends CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>(_onIncrement);
  }

  // Private: fine
  void _onIncrement(Increment event, Emitter<int> emit) => emit(state + 1);

  // Override: fine
  @override
  void onChange(Change<int> change) => super.onChange(change);

  // Static: fine
  static CounterEvent increment() => Increment();
}
```

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  avoid_bloc_public_methods: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  avoid_bloc_public_methods: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_passing_bloc_to_bloc`](/many_lints/docs/rules/bloc-riverpod/avoid-passing-bloc-to-bloc/) — Prevent Bloc/Cubit classes from depending on other Bloc/Cubit instances.
- [`prefer_bloc_extensions`](/many_lints/docs/rules/bloc-riverpod/prefer-bloc-extensions/) — Use context.read/watch instead of BlocProvider.of or RepositoryProvider.of.
- [`avoid_duplicate_bloc_event_handlers`](/many_lints/docs/rules/bloc-riverpod/avoid-duplicate-bloc-event-handlers/) — Register each bloc event type exactly once.
- [`avoid_public_notifier_properties`](/many_lints/docs/rules/bloc-riverpod/avoid-public-notifier-properties/) — Prevent public fields, getters, and setters on Notifier classes.
