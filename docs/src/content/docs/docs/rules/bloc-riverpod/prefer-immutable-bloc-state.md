---
title: prefer_immutable_bloc_state
description: "Ensure Bloc and Cubit state classes are annotated with @immutable"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_immutable_bloc_state
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Bloc / Riverpod</span>

This rule flags a Bloc or Cubit state class that is missing `@immutable`, and offers a quick fix adding it. The state class is found through the type argument of `Bloc<Event, State>` or `Cubit<State>`, then widened to every subclass and implementor **declared in the same file**.

This rule is in the **`opinionated`** preset.

## Why use this rule

`emit` compares the new state to the current one with `==` and drops it when they are equal. Mutating a state object in place and re-emitting it therefore changes nothing a listener can see: same instance, `==` holds, no rebuild. Nothing throws — the screen just does not update.

`@immutable` moves that failure to analysis time. The analyzer reports the non-final field where it is declared, so the bug is caught in the state class rather than debugged in the UI.

**See also:** [Bloc state management](https://bloclibrary.dev/bloc-concepts/#state)

## Examples

### The sealed state hierarchy

Every class in the hierarchy is reported, not just the root:

```dart
// Don't
import 'package:bloc/bloc.dart';

sealed class CounterState {}                 // LINT

class CounterInitial extends CounterState {} // LINT

class CounterLoaded extends CounterState {   // LINT
  CounterLoaded(this.count);

  int count;                                 // mutable — this is the bug
}

class CounterCubit extends Cubit<CounterState> {
  CounterCubit() : super(CounterInitial());
}
```

```dart
// Do — @immutable makes the analyzer report `int count;` as non-final
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

@immutable
sealed class CounterState {}

@immutable
class CounterInitial extends CounterState {}

@immutable
class CounterLoaded extends CounterState {
  const CounterLoaded(this.count);

  final int count;
}

class CounterCubit extends Cubit<CounterState> {
  CounterCubit() : super(CounterInitial());
}
```

### A Bloc's state is the second type argument

`Bloc<Event, State>` carries the event first, so the event classes are never reported — only the state:

```dart
// Don't
import 'package:bloc/bloc.dart';

sealed class CartEvent {}                    // not state, not reported

class CartState {                            // LINT
  CartState(this.items);

  List<String> items;
}

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(CartState(const []));
}
```

## Not for Riverpod or plain state classes

This rule recognises state **by type**, so it is completely inert in a project without the `bloc` package.

If you want the same advice for Riverpod notifier state, or for any class your project merely names `...State`, use [`prefer_immutable_state`](/many_lints/docs/rules/state-management/prefer-immutable-state/) instead. It matches on the class name and carries the `name_pattern` option.

## Known limitations

Subclasses are widened **within one file**. A state hierarchy split across files — the sealed root in `counter_state.dart`, the variants in `counter_loaded.dart` — has only the class named in the `Bloc`/`Cubit` type argument reported; the variants in other files are not, because the rule reads one compilation unit at a time.

The type argument must be written out. A Bloc that gets its state type through a generic parameter (`class Base<S> extends Bloc<Event, S>`) supplies no class name to check.

An inherited `@immutable` is not enough on the root itself — the annotation is read from the class's own metadata.

## Turning this rule off

To disable this rule:

```yaml
# many_lints.yaml
rules:
  prefer_immutable_bloc_state: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`emit_new_bloc_state_instances`](/many_lints/docs/rules/bloc-riverpod/emit-new-bloc-state-instances/) — Emit a new state instance instead of the existing state object.
- [`avoid_duplicate_bloc_event_handlers`](/many_lints/docs/rules/bloc-riverpod/avoid-duplicate-bloc-event-handlers/) — Register each bloc event type exactly once.
- [`handle_bloc_event_subclasses`](/many_lints/docs/rules/bloc-riverpod/handle-bloc-event-subclasses/) — Register a handler for every Bloc event subclass.
- [`avoid_bloc_public_methods`](/many_lints/docs/rules/bloc-riverpod/avoid-bloc-public-methods/) — Prevent public methods, getters, and setters in Bloc classes.
