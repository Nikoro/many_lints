---
title: prefer_bloc_extensions
description: "Use context.read/watch instead of BlocProvider.of or RepositoryProvider.of"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_bloc_extensions
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Bloc / Riverpod</span>

This rule flags usage of `BlocProvider.of()` and `RepositoryProvider.of()` and suggests using the shorter `context.read()` or `context.watch()` extensions instead. When `listen: true` is passed, the rule suggests `context.watch()`.

## Why use this rule

The `context.read()` and `context.watch()` extensions are shorter, more readable, and make the intent clearer. With `BlocProvider.of()`, developers can easily forget the `listen` parameter or misconfigure it. The extension methods make the distinction between one-time reads and reactive watches explicit in the method name itself.

**See also:** [BlocProvider](https://bloclibrary.dev/flutter-bloc-concepts/#blocprovider) | [context.read vs context.watch](https://bloclibrary.dev/flutter-bloc-concepts/#usage-1)

## Don't

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0);
}

class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
}

class MyRepository {}

void examples(BuildContext context) {
  final bloc = BlocProvider.of<CounterBloc>(context);
  final watched = BlocProvider.of<CounterCubit>(context, listen: true);
  final repo = RepositoryProvider.of<MyRepository>(context);
}
```

## Do

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0);
}

class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
}

class MyRepository {}

void examples(BuildContext context) {
  final bloc = context.read<CounterBloc>();
  final cubit = context.watch<CounterCubit>();
  final repo = context.read<MyRepository>();
}
```

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  prefer_bloc_extensions: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  prefer_bloc_extensions: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_bloc_public_methods`](/many_lints/docs/rules/bloc-riverpod/avoid-bloc-public-methods/) — Prevent public methods, getters, and setters in Bloc classes.
- [`avoid_passing_bloc_to_bloc`](/many_lints/docs/rules/bloc-riverpod/avoid-passing-bloc-to-bloc/) — Prevent Bloc/Cubit classes from depending on other Bloc/Cubit instances.
- [`avoid_duplicate_bloc_event_handlers`](/many_lints/docs/rules/bloc-riverpod/avoid-duplicate-bloc-event-handlers/) — Register each bloc event type exactly once.
- [`emit_new_bloc_state_instances`](/many_lints/docs/rules/bloc-riverpod/emit-new-bloc-state-instances/) — Emit a new state instance instead of the existing state object.
