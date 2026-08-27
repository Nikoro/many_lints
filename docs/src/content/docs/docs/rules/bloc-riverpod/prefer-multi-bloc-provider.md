---
title: prefer_multi_bloc_provider
description: "Use MultiBlocProvider, MultiBlocListener, or MultiRepositoryProvider instead of nesting"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_multi_bloc_provider
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Bloc / Riverpod</span>

This rule flags a `BlocProvider`, `BlocListener` or `RepositoryProvider` whose `child:` is another widget of the **same** type, and offers a quick fix collapsing the nest into `MultiBlocProvider`, `MultiBlocListener` or `MultiRepositoryProvider`.

Only the outermost provider of a nest is reported, so a three-deep pyramid produces one diagnostic, not two.

## Why use this rule

The nested and the flattened forms behave identically — this is readability. A `Multi*` list is a flat list of providers: adding one is a one-line diff, and removing one does not require re-indenting everything below it. A nest makes every such change touch the whole block.

**See also:** [MultiBlocProvider](https://bloclibrary.dev/flutter-bloc-concepts/#multiblocprovider) | [MultiBlocListener](https://bloclibrary.dev/flutter-bloc-concepts/#multibloclistener) | [MultiRepositoryProvider](https://bloclibrary.dev/flutter-bloc-concepts/#multirepositoryprovider)

## Examples

### The app-root provider pyramid

```dart
// Don't — one diagnostic, on the outermost BlocProvider
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0);
}

class TimerCubit extends Cubit<int> {
  TimerCubit() : super(0);
}

class ThemeCubit extends Cubit<bool> {
  ThemeCubit() : super(false);
}

Widget buildApp(Widget home) => BlocProvider<CounterBloc>(
  create: (context) => CounterBloc(),
  child: BlocProvider<TimerCubit>(
    create: (context) => TimerCubit(),
    child: BlocProvider<ThemeCubit>(
      create: (context) => ThemeCubit(),
      child: home,
    ),
  ),
);
```

```dart
// Do — the quick fix produces this
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0);
}

class TimerCubit extends Cubit<int> {
  TimerCubit() : super(0);
}

class ThemeCubit extends Cubit<bool> {
  ThemeCubit() : super(false);
}

Widget buildApp(Widget home) => MultiBlocProvider(
  providers: [
    BlocProvider<CounterBloc>(create: (context) => CounterBloc()),
    BlocProvider<TimerCubit>(create: (context) => TimerCubit()),
    BlocProvider<ThemeCubit>(create: (context) => ThemeCubit()),
  ],
  child: home,
);
```

### Listeners nest the same way

```dart
// Don't
BlocListener<AuthBloc, bool>(
  listener: (context, loggedIn) {},
  child: BlocListener<CartBloc, int>(
    listener: (context, count) {},
    child: const HomeView(),
  ),
)
```

```dart
// Do
MultiBlocListener(
  listeners: [
    BlocListener<AuthBloc, bool>(listener: (context, loggedIn) {}),
    BlocListener<CartBloc, int>(listener: (context, count) {}),
  ],
  child: const HomeView(),
)
```

## Known limitations

Only a nest of the **same** type is reported. A `BlocProvider` wrapping a `RepositoryProvider` cannot be collapsed into one `Multi*` widget, so it is left alone:

```dart
// Not reported — different types, nothing to merge
RepositoryProvider<UserRepository>(
  create: (context) => UserRepository(),
  child: BlocProvider<AuthBloc>(
    create: (context) => AuthBloc(),
    child: const HomeView(),
  ),
)
```

The nesting must go through `child:`. A provider reached through any other argument, or through a builder callback, is not matched.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  prefer_multi_bloc_provider: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  prefer_multi_bloc_provider: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_bloc_public_methods`](/many_lints/docs/rules/bloc-riverpod/avoid-bloc-public-methods/) — Prevent public methods, getters, and setters in Bloc classes.
- [`avoid_duplicate_bloc_event_handlers`](/many_lints/docs/rules/bloc-riverpod/avoid-duplicate-bloc-event-handlers/) — Register each bloc event type exactly once.
- [`avoid_passing_bloc_to_bloc`](/many_lints/docs/rules/bloc-riverpod/avoid-passing-bloc-to-bloc/) — Prevent Bloc/Cubit classes from depending on other Bloc/Cubit instances.
- [`emit_new_bloc_state_instances`](/many_lints/docs/rules/bloc-riverpod/emit-new-bloc-state-instances/) — Emit a new state instance instead of the existing state object.
