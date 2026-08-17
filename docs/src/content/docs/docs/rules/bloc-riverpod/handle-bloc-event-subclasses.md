---
title: handle_bloc_event_subclasses
description: "Register a handler for every Bloc event subclass"
sidebar:
  label: handle_bloc_event_subclasses
---

<span class="rule-badge rule-badge--version">v0.10.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Bloc / Riverpod</span>

This rule flags a `Bloc` whose sealed event hierarchy has a subclass with no `on<E>` handler. Adding an unregistered event does nothing at all at runtime.

## Why use this rule

`on<E>` registration is a runtime lookup keyed by type. If no handler is registered for an event, `add(MyEvent())` returns normally, emits no state, throws nothing and logs nothing. The feature simply does not work.

The gap almost always appears later: a new event class joins the hierarchy and the matching `on<E>` is forgotten. Because the compiler cannot see the omission, only a test that exercises that exact event will catch it — and the missing event is usually the one no test covers yet.

**See also:** [bloc: Bloc.on](https://pub.dev/documentation/bloc/latest/bloc/Bloc/on.html)

## Don't

```dart
sealed class CounterEvent {}
class Increment extends CounterEvent {}
class Decrement extends CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
    // `Decrement` is never handled — adding it does nothing
  }
}
```

## Do

```dart
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
    on<Decrement>((event, emit) => emit(state - 1));
  }
}
```

A handler for the base type covers every subclass:

```dart
on<CounterEvent>((event, emit) => ...);
```

## Known limitations

Only **sealed** event hierarchies are checked. A sealed type may only be extended within its own library, so its subtypes are knowable. For an open base class a subtype may live in any library, so "every subtype" cannot be computed and a report would be guesswork — make the event base `sealed` to get this check, which is good practice regardless.

Handlers are found by scanning the class for `on<E>(...)` calls, so a registration made outside the Bloc, or through a helper, is not detected.

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`handle_bloc_event_subclasses: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  handle_bloc_event_subclasses: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_duplicate_bloc_event_handlers`](/many_lints/docs/rules/bloc-riverpod/avoid-duplicate-bloc-event-handlers/) — Register each bloc event type exactly once.
- [`emit_new_bloc_state_instances`](/many_lints/docs/rules/bloc-riverpod/emit-new-bloc-state-instances/) — Emit a new state instance instead of the existing state object.
- [`prefer_immutable_bloc_state`](/many_lints/docs/rules/bloc-riverpod/prefer-immutable-bloc-state/) — Ensure Bloc and Cubit state classes are annotated with @immutable.
- [`avoid_bloc_public_methods`](/many_lints/docs/rules/bloc-riverpod/avoid-bloc-public-methods/) — Prevent public methods, getters, and setters in Bloc classes.
