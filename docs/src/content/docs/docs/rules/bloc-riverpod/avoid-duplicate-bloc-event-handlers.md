---
title: avoid_duplicate_bloc_event_handlers
description: "Register each bloc event type exactly once"
sidebar:
  label: avoid_duplicate_bloc_event_handlers
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Bloc & Riverpod</span>

This rule flags a bloc constructor that registers the same event type with `on<E>` more than once.

## Why use this rule

`Bloc.on<E>` asserts that each event type has exactly one handler. A second registration for the same type throws a `StateError`:

> `on<IncrementEvent>` was called multiple times.

Because the registration happens in the constructor, the throw fires the first time the bloc is instantiated — often deep in a provider or a route builder, far from the duplicated line. Catching it at analysis time turns a runtime crash into a squiggle on the exact call.

The usual cause is a copy-pasted `on<...>` line where the type argument was not updated.

**See also:** [bloc: Bloc.on](https://pub.dev/documentation/bloc/latest/bloc/Bloc/on.html)

## Don't

```dart
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<IncrementEvent>((event, emit) => emit(state + 1));
    // Throws at construction — the type argument was never updated
    on<IncrementEvent>((event, emit) => emit(state - 1));
  }
}
```

## Do

```dart
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<IncrementEvent>((event, emit) => emit(state + 1));
    on<DecrementEvent>((event, emit) => emit(state - 1));
  }
}
```

If two behaviours genuinely belong to one event, merge them into a single handler.

## Known limitations

Registrations are tracked per constructor. A bloc with two constructors that each register the same event is not flagged, because only one of them runs for any given instance.

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_duplicate_bloc_event_handlers: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

### Options

Configure in `many_lints.yaml` at your package root:

```yaml
rules:
  avoid_duplicate_bloc_event_handlers:
    additional_methods: [onEvent]
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `additional_methods` | list of strings | `[]` | Extra registration methods treated like Bloc's `on`, for a project wrapper that forwards to it |

Alternatively, use a top-level `many_lints:` section in `analysis_options.yaml`.
Note this section does **not** inherit through `include:`; when both sources
exist, `many_lints.yaml` wins and the section is ignored entirely.
