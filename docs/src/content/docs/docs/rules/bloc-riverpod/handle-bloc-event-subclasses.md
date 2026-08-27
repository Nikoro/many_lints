---
title: handle_bloc_event_subclasses
description: "Register a handler for every Bloc event subclass"
sidebar:
  label: handle_bloc_event_subclasses
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Bloc / Riverpod</span>

This rule flags a `Bloc` whose sealed event hierarchy has a subclass with no `on<E>` handler. Adding an unregistered event does nothing at all at runtime.

## Why use this rule

`on<E>` registration is a runtime lookup keyed by type. If no handler is registered for an event, `add(MyEvent())` returns normally, emits no state, throws nothing and logs nothing. The feature simply does not work.

The gap almost always appears later: a new event class joins the hierarchy and the matching `on<E>` is forgotten. Because the compiler cannot see the omission, only a test that exercises that exact event will catch it — and the missing event is usually the one no test covers yet.

**See also:** [bloc: Bloc.on](https://pub.dev/documentation/bloc/latest/bloc/Bloc/on.html)

## Examples

### A new event class with no handler

The usual shape: `Decrement` was added to the hierarchy and the matching `on<Decrement>` was never written. It compiles, `add(Decrement())` returns normally, and nothing happens.

```dart
// Don't
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

```dart
// Do — one registration per subclass
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
    on<Decrement>((event, emit) => emit(state - 1));
  }
}
```

### One handler for the whole hierarchy

Registering the sealed base covers every subclass, so the rule reports nothing. Switch on the event inside — the `sealed` base makes the `switch` exhaustive, so the compiler catches the next new event class for you:

```dart
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<CounterEvent>((event, emit) {
      emit(switch (event) {
        Increment() => state + 1,
        Decrement() => state - 1,
      });
    });
  }
}
```

Do not write the empty form `on<CounterEvent>((event, emit) => emit(state))` just to silence this rule. It satisfies this check but is reported by [`emit_new_bloc_state_instances`](/many_lints/docs/rules/bloc-riverpod/emit-new-bloc-state-instances/), which is in the `core` preset and therefore on in every configuration that turns anything on — `emit(state)` re-emits the current instance, which Bloc drops as equal, so it also does nothing at runtime.

### An open hierarchy is never reported

Only **sealed** event bases are checked. A subtype of an open class may live in any library, so "every subtype" cannot be computed:

```dart
// Not reported — `OpenEvent` is not sealed, so `OpenDecrement` is invisible
class OpenEvent {}

class OpenIncrement extends OpenEvent {}

class OpenDecrement extends OpenEvent {}

class OpenBloc extends Bloc<OpenEvent, int> {
  OpenBloc() : super(0) {
    on<OpenIncrement>((event, emit) => emit(state + 1));
  }
}
```

Marking the base `sealed` is what turns the check on.

## Known limitations

Handlers are found by scanning the Bloc class for `on<E>(...)` calls, so a registration made outside the class, or through a helper method that forwards to `on`, is not detected and the event is reported as unhandled.

Only the event type argument of `extends Bloc<E, S>` is read. A Bloc that reaches its event type through a generic type parameter or an intermediate base class is not checked.

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
